# bootstrap
Minimal Bootstrap Mike McLean Shell Environment

## Background
I store all of my Shell Init and various dotfiles in a `~/.init`
directory in my home directory. I keep this repository version
controlled in Git and stored in a Private Repository (on AWS Code
Commit as `DotInit`).

## Purpose
When configuring a new system I need a way to get my `~/.init`
configuration folder onto it. This minimal Bootstrap project will get
a copy of `~/.init` onto the target system.

If `~/.init` does not exist:

- If the target system already contains a copy of the `DotInit`
  directory as a synchronized copy via Microsoft OneDrive, the script
  will create `~/.init` a symbolic link to that version.

- On a system without a synchronized copy via Microsoft OneDrive this
  script will execute a `git clone` from AWK Code Commit to `~/.init`.
  The code to clone from AWS CodeCommit requires the following:
  - `curl` or `wget`
  - `ssh`
  - `git` (at least version 2.3.0 which supports the `GIT_SSH_COMMAND`
    environment variable)
  - A copy of my main SSH private key `id.mike.mclean`, placed on the
    system manually. The script will ask for the path to this file as
    input.
    - TODO - Change to GPG Keys not SSH Keys

# Usage
On a new target system execute:

``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/SkydiveMike/bootstrap/master/bootstrap.sh)
```
or

``` shell
bash <(wget -qO-  https://raw.githubusercontent.com/SkydiveMike/bootstrap/master/bootstrap.sh)
```
