
# Copy the config file over

$source = join-path $Jsh.ConfigPath "Data\.gitconfig"
copy -fo $source $env:userprofile
$source = join-path $Jsh.ConfigPath "Data\.gitignore"
copy -fo $source $env:userprofile
