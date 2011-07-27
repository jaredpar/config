
$check = $args[0]
if ( $check -eq "check" ) {

    # Check and see if the community extensions are already installed on this
    # machine.  
    $path = join-path (Get-ProgramFiles32) "Vim\vim72\gvim.exe"
    return -not (test-path $path)
}

# Uninstall Vim 7.1 if it is currently installed.  "uninstal.exe" is
# not a typo.  It actually is spelled with only one "l"
$oldPath= join-path (Get-ProgramFiles32) "Vim\vim71\uninstal.exe"
if ( test-path $oldPath) { 
    & $oldPath
}

# Run the file 
$filePath = join-path $jsh.UtilsRawPath "gvim72.exe"

write-host "Running gvim setup"
$s = [Diagnostics.Process]::Start($filePath)
$s.WaitForExit()
