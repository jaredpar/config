
# Global Settings
git config --global user.name "Jared Parsons"
git config --global user.email "jaredpparsons@gmail.com"
git config --global core.autocrlf false

$file = join-path $Jsh.ConfigPath Data\.gitignore
git config --global core.excludesfile "$file"
