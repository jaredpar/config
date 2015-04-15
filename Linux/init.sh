#!/bin/bash

ln -sf ~/Documents/config/Linux/.vimrc ~/.vimrc

if [ -L ~/.vim ]; then
    rm ~/.vim
fi
ln -sf ~/Documents/config/Linux/vimfiles ~/.vim

git config --global user.email "jaredpparsons@gmail.com"
git config --global user.name "Jared Parsons"
