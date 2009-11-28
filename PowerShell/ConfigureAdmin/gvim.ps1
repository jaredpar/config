
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

# Download the file and run it.
$filePath = join-path $env:temp "gvim72.exe"
if ( test-path $filePath ) {
    del --force $filePath
}

write-host "Downloading setup file"
wget http://rantpack.org/Drops/gvim72.exe $filePath

write-host "Running setup"
$s = [Diagnostics.Process]::Start($filePath)
$s.WaitForExit()
