
# Copy Reflector.exe to the desktop

$dest = join-path $env:UserProfile "Desktop"

# First remove any old versions
foreach ( $i in "Reflector.exe","Reflector.exe.config","Reflector.cfg") {
    $old = join-path $dest $i
    if ( test-path $old ) { 
        rm $old 
    }
}

# Copy the new one and pin it to the task bar
$source = join-path $PSScriptRoot "Reflector" 
$dest = join-path $dest "Reflector"
& $PSScriptRoot\SmartDeployDirectory.ps1 $source $dest 
& $PSScriptRoot\PinToTaskbar.ps1 (join-path $dest "Reflector.exe")
