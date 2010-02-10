
# Copy Reflector.exe to the desktop

$source = join-path $jsh.UtilsRawPath "Reflector.exe"
$dest = join-path $env:UserProfile "Desktop"
copy -force $source $dest
