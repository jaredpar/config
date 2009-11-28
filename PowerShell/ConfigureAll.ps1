
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 

# Run the normal configuration scripts first
if ( ($args.Length -eq 0) -or ($args[0] -ne "AdminOnly") ) {

    pushd (join-path $scriptPath "Configure" )
    echo "Running Configuration Scripts"
    foreach ( $file in (dir *.ps1)) {
        & $file.FullName
    }

    popd
}

# First, go ahead and configure the administrative tasks
pushd $(join-path $Jsh.ScriptPath "ConfigureAdmin")
write-host "Checking the Admin Configuration Scripts"
if ( -not (Test-Admin) ) {

    # When I'm not an administrator i can only check and see if the scripts need to 
    # be run and then re-run this as an admin.  Don't just re-run as an admin because
    # it produces a lot of annoying prompts
    [bool]$anyNeeded = $false
    foreach ( $file in (dir *.ps1)) {

        # First check and see if any of the scripts need to run.  If so then run the 
        # administrator ones
        # Return $true = Needs to run
        # Return $false = Does not need to run
        echo ("Checking " + $file.FullName)
        $needed = & $file.FullName "check"
        if ( $needed ) {
            write-host ("Need: {0}" -f (split-path -leaf $file.FullName))
            $anyNeeded = $true
        }
    }

    if ( $anyNeeded ) {
        # Run the configure as an administrator 
        Invoke-ScriptAdmin $(join-path $Jsh.ScriptPath "ConfigureAll.ps1") "AdminOnly" -waitForExit

        # Reload the profile after running the adiminstrator configureation 
        # as it might update snapin's that we want to load
        . $(join-path $Jsh.ScriptPath "Profile.ps1")
    }

} else {
    # I'm an admin so check and run at the same time

    $ranOne = $false
    foreach ( $file in (dir *.ps1)) {
        $needed = & $file.FullName "check"
        if ( $needed ) {
            $run = read-host "Run $($file.Name)? (Y/N): " 
            if ( $run -eq "y" ) {
                & $file.FullName "run" 
                $ranOne = $true
            }
        }
    }

    if ( $ranOne ) {
        # Reload the profile after running the adiminstrator configureation 
        # as it might update snapin's that we want to load
        . $(join-path $Jsh.ScriptPath "Profile.ps1")
    }
}
popd

