
$check = $args[0]
if ( $check -eq "check" ) {

    # Don't install this on test machines
    if ( $Jsh.IsTestMachine ) {
        return $false
    }

    # Check and see if the community extensions are already installed on this
    # machine.  
    $progPath = Get-Ternary (Test-Win64) ${env:ProgramFiles(x86)} $env:ProgramFiles
    $installPath = join-path $progPath "PowerShell Community Extensions"
    if ( test-path $installPath ) {
        return $false;
    }

    return $true
}

# Download the file and run it.
$filePath = join-path $env:temp "PowerShellCX_1.1_Setup.exe"
if ( test-path $filePath ) {
    del --force $filePath
}

write-host "Downloading setup file"
wget http://rantpack.org/Drops/PowerShellCX_1.1_Setup.exe $filePath

write-host "Running setup"
$s = [Diagnostics.Process]::Start($filePath)
$s.WaitForExit()
