
# Global Settings
git config --global user.name "Jared Parsons"
git config --global user.email "jaredpparsons@gmail.com"
git config --global core.autocrlf false

# Colors are pretty 
git config --global color.branch always
git config --global color.showbranch always
git config --global color.status always


$file = join-path $Jsh.ConfigPath Data\.gitignore
git config --global core.excludesfile "$file"
