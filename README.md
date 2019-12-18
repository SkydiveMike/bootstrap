# bootstrap
Minimal Bootstrap Mike McLean Shell Environment

## Background
I store all of my Shell Init and various dotfiles in a `~/.init`
directory in my home directory. I keep this repository version
controlled in Git and stored in a Private Repository (on AWS Code
Commit).

## Purpose
When configuring a new system I need a way to get my `~/.init`
configuration folder onto it. This minimal Bootstrap project will get
a copy of `~/.init` onto the target system.

## Prerequisite

The target system _must_ have `ssh` and `git` *or* have a copy of
`~/.init` from another file synchronization service (typcially OneDrive).

If `~/.init` does not exist:
- On a system with Microsoft OneDrive (typically a Mac), create
  `~/.init` as a symlink to
  `~/OneDrive/Mike-Documents/development/DotInit`
- On a system without Microsoft OneDrive execute a `git clone` from
  AWK Code Commit to `~/.init`.
  - For this we need a copy of my main SSH private key
    `id.mike.mclean`. I will need to provide a path to this file as
    input to the script.
