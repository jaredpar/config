#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ln -sf $THIS_DIR/.vimrc ~/.vimrc

if [ -L ~/.vim ]; then
    rm ~/.vim
fi
ln -sf $THIS_DIR/vimfiles ~/.vim

git config --global user.email "jaredpparsons@gmail.com"
git config --global user.name "Jared Parsons"
git config --global user.signkey 58B3065D
git config --global commit.gpgsign true
git config --global core.editor "vim"
