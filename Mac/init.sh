
#!/bin/bash

SOURCE=~/code/config/Mac

ln -sf $SOURCE/.vimrc ~/.vimrc
cp $SOURCE/.inputrc ~/.inputrc

git config --global user.email "jaredpparsons@gmail.com"
git config --global user.name "Jared Parsons"
