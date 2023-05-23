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
ln -sf $PARENT_DIR/CommonData/.gitconfig  ~/.gitconfig
mkdir -p "$THIS_DIR/Local"

BASHRC_LOCAL="$THIS_DIR/Local/bashrc-local.sh"
if [ ! -f "$BASHRC_LOCAL" ]; then
    echo "# Machine specific bash goes here" > $BASHRC_LOCAL
    chhmod +x $BASHRC_LOCAL
fi

