#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ln -sf $THIS_DIR/.vimrc ~/.vimrc

if [ -L ~/.vim ]; then
    rm ~/.vim
fi
ln -sf $THIS_DIR/vimfiles ~/.vim
ln -sf $THIS_DIR/.bashrc ~/.bashrc

git config --global user.email "jaredpparsons@gmail.com"
git config --global user.name "Jared Parsons"
git config --global core.editor "vim"
git config --global fetch.prune true
git config --global push.default current
git config --global commit.gpgsign false
