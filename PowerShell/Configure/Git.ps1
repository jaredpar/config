
# Copy the config file over

$source = join-path $Jsh.ConfigPath "Data\.gitconfig"
copy -fo $source $env:userprofile
