
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 

# Run the normal configuration scripts first
pushd (join-path $scriptPath "Configure" )
echo "Running Configuration Scripts"
foreach ( $file in (dir *.ps1)) {
    & $file.FullName
}

popd

# First, go ahead and configure the administrative tasks
pushd $(join-path $Jsh.ScriptPath "ConfigureAdmin")
write-host "Checking the Admin Configuration Scripts"

foreach ( $file in (dir *.ps1)) {
    $needed = & $file.FullName "check"
    if ( $needed ) {
        $run = read-host "Run $($file.Name)? (Y/N): " 
        if ( $run -eq "y" ) {
            Invoke-ScriptAdmin $file.FullName -waitForExit 
        }
    }
}
popd

# Reload the profile after running the adiminstrator configureation 
# as it might update snapin's that we want to load
. $(join-path $Jsh.ScriptPath "Profile.ps1")

