#!/bin/bash

DIR=$(dirname $(readlink -f $0))

# Setup some helpful Git aliases
git config --global alias.lg "log --graph --decorate --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global alias.lga "log --graph --decorate --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative --all"
git config --global alias.st "status"
git config --global alias.ci "commit"
git config --global alias.br "branch"
git config --global alias.co "checkout"
git config --global alias.df "diff"
git config --global alias.dc "diff --cached"
git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit"
git config --global alias.lola "log --graph --decorate --pretty=oneline --abbrev-commit --all"
git config --global alias.ls "ls-files"
git config --global alias.ign "ls-files -o -i --exclude-standard"
git config --global color.ui "auto"
git config --global branch.current "yellow reverse"
git config --global branch.local "yellow"
git config --global branch.remote "green"
git config --global diff.meta "yellow bold"
git config --global diff.frag "magenta bold"
git config --global diff.old "red bold"
git config --global diff.new "green bold"
git config --global status.added "yellow"
git config --global status.changed "green"
git config --global status.untracked "cyan"

# Install the bash hook
if [[ -z $(grep GIT-BASH-MARKER ~/.bashrc) ]]; then
    echo >> ~/.bashrc
    echo ". ${DIR}/bash-git-prompt-hook.sh # GIT-BASH-MARKER" >> ~/.bashrc
fi