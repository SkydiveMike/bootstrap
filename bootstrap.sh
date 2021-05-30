#!/bin/bash

############################################################
# Mike McLean minimal shell environment Bootstrap          #
############################################################

## Configuration

DOTINIT="$HOME/.init"
REQUIRED_GIT_VERSION="2.3.0"
DOTINIT_REPO="ssh://APKAJQ5X5AT4DBLNEU6Q@git-codecommit.us-east-1.amazonaws.com/v1/repos/Init-Files"

# Guarantee our OSNAME
if [ "X$OSNAME" = "X" ]; then
    OSNAME=$(uname -s)
fi

############################################################
# Main function; get a clean copy of ~/.init on the system #
############################################################

bootstrap_main () {
    if [[ -d "$DOTINIT" ]] && [[ -r "$DOTINIT" ]]; then
        echo "${HOME}/.init exists as a readable directory"
    else
        if [ $? = 1 ]; then # Proceed to Git Clone
            ########################################################
            # Given that no existing .init directory exists, we no #
            #  must clone a copy from AWS CodeCommit. This in turn #
            #  requires a valid SSH key.                           #
            ########################################################
            echo -n "${HOME}/.init NOT FOUND; Need to Clone from AWS CodeCommit. Checking prerequisites ... "
            check_git # check_git will exit the script ob failure
            echo "PASS"
            echo
            check_ssh_agent
            get_ssh_key # get_ssh_key will exit the script on failure
            echo
            echo "Attempting Clone from AWS CodeCommit."
            echo

            if ! GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -i $private_key" git clone --recurse-submodules "$DOTINIT_REPO" "$DOTINIT" 2>&1; then
                echo "Git clone failed."
                exit 1
            else
                # Fix permission on SSH Keys
                chmod go-rw "$DOTINIT"/dotfiles/ssh/ssh/id*[^p][^u][^b]
            fi
        fi
    fi
    echo
    echo "Next step: cd into $HOME/.init and run: ssh-agent $HOME/.init/install.sh"
}

############################################################
# Compare dotted version strings.                          #
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
            echo "This script requires Git Version ≥ $REQUIRED_GIT_VERSION; found installed git version $GIT_VERSION"
            exit 1
        fi
    else
        echo "This script requires Git Version ≥ $REQUIRED_GIT_VERSION; git not found"
        exit 1
    fi
}

#################################################################
# Check for a running ssh-agent; fail if none exists. We should #
# always have one since the README instructs us to run with     #
# ssh-agent as the parent process.                              #
#################################################################
check_ssh_agent () {
    if [ -n "${SSH_AGENT_PID+set}" ] && ps -p "${SSH_AGENT_PID}" >/dev/null; then
        echo "Found an SSH Agent at ${SSH_AGENT_PID}; attempting to use it"
    else
        echo "This script requires a running ssh-agent."
        exit 1
    fi
}

######################################################################
# Prompt the user for an ssh key file to use as credintials to AWS   #
# CodeCommit Set the variable $private_key to a valid, readable file #
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
    if ! ssh-add "$private_key"; then
        echo "Failed to add $private_key to SSH_AGENT_PID $SSH_AGENT_PID"
        exit 1
    fi
}

bootstrap_main
