
$script:target = join-path $jsh.UtilsRawPath "JshCmdlet.dll"
$script:current = get-pssnapin JshCmdLet -registered -ea SilentlyContinue
$script:installutil = "$env:windir\Microsoft.Net\Framework\v2.0.50727\installutil.exe" 
$check = $args[0]
if ( $check -eq "check" ) {

    # Don't install on test machines
    if ( $Jsh.IsTestMachine ) {
        return $false
    }

    # Check to see if anything is registered
    if ( $current -eq $null ) {
        return $true;
    }

    # Make sure it's in the correct location
    if ( $target -ne $current.ModuleName ) {
        return $true;
    }


    return $false;
}

# Remove the current if present
if ( $current -ne $null ) {
    & $installutil /u ($current.ModuleName)
}

# Make sure we are sync'd
if ( -not (test-path $target) ) {
    svn update $Jsh.UtilsRawPath
}

# Register it
& $installutil $target
