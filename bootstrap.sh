#!/bin/bash

############################################################
## Mike McLean minimal shell environment Bootstrap        ##
############################################################

## Configuration

DOTINIT="$HOME/.init"
ONEDRIVE_DOTINIT="$HOME/OneDrive/Mike-Documents/development/DotInit"
REQUIRED_GIT_VERSION="2.3.0"
DOTINIT_REPO="ssh://APKAJQ5X5AT4DBLNEU6Q@git-codecommit.us-east-1.amazonaws.com/v1/repos/Init-Files"

# Guarantee our OSNAME
if [ "X$OSNAME" = "X" ]; then
    OSNAME=$(uname -s)
fi

##############################################################
## main function; get a clean copy of ~/.init on the system ##
##############################################################

main () {
    if [[ -d "$DOTINIT" ]] && [[ -r "$DOTINIT" ]]; then
        echo "${HOME}/.init exists as a readable directory"
    else
        check_onedrive # check_onedrive will exit the script on failure or return 1 if we need to proceed to git clone
        if [ $? = 1 ]; then # Proceed to Git Clone
            ###################################################################
            ## Given that no existing .init directory exists and no OneDrive ##
            ## version exists; we no must clone a copy from AWS CodeCommit.  ##
            ## This in turn requires a valid SSH key.                        ##
            ###################################################################
            echo -n "OneDrive Version of DotInit NOT FOUND; Need to Clone from AWS CodeCommit. Checking prerequisites ... "
            check_git # check_git will exit the script ob failure
            echo "PASS"
            echo
            get_ssh_key # get_ssh_key will exit the script on failure
            echo
            echo "Attempting Clone from AWS CodeCommit."
            echo

            if ! GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -i $private_key" git clone --recurse-submodules "$DOTINIT_REPO" "$DOTINIT" 2>&1; then
                echo "Git clone failed."
                exit 1
            fi
        fi
    fi
    echo
    echo "Next step: cd into $HOME/.init and run $HOME/.init/install.sh"
}

############################################################
## Compare dotted version strings.                        ##
############################################################
vercomp () {
    # https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
    if [[ "$1" == "$2" ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1 ver2
    read -r -a ver1 <<< "$1"
    read -r -a ver2 <<< "$2"
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

check_git () {
    # Check presence and version of Git
    if type -a git 2>/dev/null >/dev/null; then
        GIT_VERSION=$(git --version | awk '{print $3;}')
        vercomp "$GIT_VERSION" "$REQUIRED_GIT_VERSION"
        if [ $? = 2 ]; then
            echo "FAIL"
            echo "This script requires Git Version ≥ $REQUIRED_GIT_VERSION; found installed git version $GIT_VERSION"
            exit 1
        fi
    else
        echo "FAIL"
        echo "This script requires Git Version ≥ $REQUIRED_GIT_VERSION; git not found"
        exit 1
    fi
}

######################################################################
## Prompt the user for an ssh key file to use as credintials to AWS ##
## CodeCommit                                                       ##
## Set the variable $private_key to a valid, readable file          ##
######################################################################
get_ssh_key () {
    while true
    do
        # prompt user, and read the file name
        read -erp "Enter Path to ssh private key file with access to AWS CodeCommit: " private_key
        private_key="${private_key/#\~/$HOME}"

        # Check that we can read the file
        [[ -r "$private_key" ]] && break

        # Issue error
        echo "Error: Cannot read file '$private_key'"
    done
    echo "Set private_key to $private_key"
}

####################################################################
## Check for a OneDrive copy of DotInit and symbolic link it into ##
## ~/.init if possible. Exit script on complete failure, return 1 ##
## if need to proceed to git clone                                ##
####################################################################

check_onedrive () {
    # Check for DotInit in Microsoft One Drive
    if [ "$OSNAME" == "Darwin" ] && [[ -d "$ONEDRIVE_DOTINIT" ]] && [[ -r "$ONEDRIVE_DOTINIT" ]]; then
        echo -n "OneDrive Version of DotInit Exists; Linking $ONEDRIVE_DOTINIT to $DOTINIT ... "
        LN_OUT=$(/bin/ln -s "$ONEDRIVE_DOTINIT" "$DOTINIT" 2>&1)
        if [[ -d "$DOTINIT" ]] && [[ -r "$DOTINIT" ]]; then
            echo "Success"
            return 0
        else
            echo "FAIL"
            echo "$LN_OUT"
            exit 1
        fi
    else
        return 1
    fi
}

main
