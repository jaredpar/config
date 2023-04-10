#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ln -sf $THIS_DIR/.vimrc ~/.vimrc

if [ -L ~/.vim ]; then
    rm ~/.vim
fi
ln -sf $THIS_DIR/vimfiles ~/.vim
ln -sf $THIS_DIR/.bashrc ~/.bashrc
ln -sf $THIS_DIR/../CommonData/.gitconfig  ~/.gitconfig

