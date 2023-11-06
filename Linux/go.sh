#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR=$(realpath "$THIS_DIR/..")
ln -sf $THIS_DIR/.vimrc ~/.vimrc

if [ -L ~/.vim ]; then
    rm ~/.vim
fi

if [ -f ~/.bashrc ]; then
    rm ~/.bashrc
fi

echo "source $THIS_DIR/.bashrc $THIS_DIR" > ~/.bashrc

ln -sf $THIS_DIR/vimfiles ~/.vim

echo "Configure Git"
git config --global user.name "Jared Parsons"
git config --global user.email jared@paranoidcoding.org
git config --global fetch.prune true
git config --global core.longpaths true
git config --global push.default current
git config --global commit.gpgsign false
git config --global alias.assume 'update-index --assume-unchanged'
git config --global alias.unassume 'update-index --no-assume-unchanged'
git config --global core.editor vim

mkdir -p "$THIS_DIR/Local"

BASHRC_LOCAL="$THIS_DIR/Local/bashrc-local.sh"
if [ ! -f "$BASHRC_LOCAL" ]; then
    echo "# Machine specific bash goes here" > $BASHRC_LOCAL
    chmod +x $BASHRC_LOCAL
fi

