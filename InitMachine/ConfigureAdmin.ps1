
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 
pushd $(join-path $scriptPath "AdminScripts")

# Load up the profile so we can get some common functionality here
. $(join-path $scriptPath "..\Powershell\Profile.ps1")

write-host "Checking the Admin Configuration Scripts"

# Run all of the admin configuration scripts
foreach ( $file in (dir *.ps1)) {
    $needed = & $file.FullName "check"
    if ( $needed ) {
        $run = read-host "Run $($file.Name)? (Y/N): " 
        if ( $run -eq "y" ) {
            & $file.FullName
        }
    }
}

popd
