
# Copy Console.exe to the desktop directory and pin it 

$dest = join-path (join-path $env:UserProfile "Desktop") "Console"
$source = join-path $PSScriptRoot "Console" 
& $PSScriptRoot\SmartDeployDirectory.ps1 $source $dest 
& $PSScriptRoot\PinToTaskbar.ps1 (join-path $dest "Console.exe")
