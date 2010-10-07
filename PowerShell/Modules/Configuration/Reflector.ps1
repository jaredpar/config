
# Copy Reflector.exe to the desktop

$dest = join-path $env:UserProfile "Desktop"

# First remove any old versions
foreach ( $i in "Reflector.exe","Reflector.exe.config","Reflector.cfg") {
    $old = join-path $dest $i
    if ( test-path $old ) { 
        rm $old 
    }
}

# Copy the new one
$source = join-path $PSScriptRoot "Reflector" 
$dest = join-path $dest "Reflector"
if ( -not (test-path $dest ) ) { 
    mkdir $dest | out-null
}
copy -force "$source\*" $dest
