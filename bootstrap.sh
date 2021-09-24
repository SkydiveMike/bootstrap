#!/bin/bash

############################################################
# Mike McLean minimal shell environment Bootstrap          #
############################################################

## Configuration

DOTINIT="$HOME/.init"
# This AWS SSH Key ID = id.mike.mclean
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
        echo "${DOTINIT} exists as a readable directory"
    else
        #############################################################
        # Given that no existing .init directory exists, we no must #
        # clone a copy from AWS CodeCommit. This in turn requires a #
        # valid SSH key.                                            #
        #############################################################
        echo -n "${DOTINIT} NOT FOUND; Need to Clone from AWS CodeCommit. Checking prerequisites ... "
        check_git # check_git will exit the script on failure
        echo "PASS"
        echo
        check_ssh_agent
        get_ssh_key # get_ssh_key will exit the script on failure
        echo
        echo "Attempting Clone from AWS CodeCommit (using chezmoi)."
        echo

        if ! GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -i $private_key" sh -c "$(curl --noproxy "*" -fsLS git.io/chezmoi)" -d -b "$HOME/.local/bin" -- init --source "$DOTINIT" "$DOTINIT_REPO" 2>&1; then
            echo "Git clone via chezmoi failed."
            exit 1
        else
            # Fix permission on SSH Keys
            chmod go-rw "$DOTINIT"/dotfiles/ssh/ssh/id*[^p][^u][^b]
        fi
    fi
    echo
    echo "Next steps:"
    echo "- Restart your shell"
    echo "- cd into ${DOTINIT} and run: ssh-agent $HOME/.init/install.sh"
}

check_git () {
    # Check presence of Git
    if ! type -a git 2>/dev/null >/dev/null; then
        echo "This script requires Git; git not found"
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
