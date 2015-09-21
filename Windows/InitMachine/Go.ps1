
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 

# Is this a Win64 machine irrespective of whether or not we are currently
# running in a 64 bit process
$isWin64 = test-path (join-path $env:WinDir "SysWow64") 

# Enable the execution of scripts on this machine 
$psExe = join-path $env:windir "System32\WindowsPowerShell\v1.0\powershell.exe"
& $psExe -Command ". set-executionpolicy -scope CurrentUser remotesigned"

if ($isWin64) {
    $psExe32 = join-path $env:windir "syswow64\WindowsPowerShell\v1.0\powershell.exe"
    & $psExe32 -Command ". set-executionpolicy -scope CurrentUser remotesigned"
}

# Get the profile into a known state which includes a lot of 
# helper modules 
. $(join-path $scriptPath "..\Powershell\Profile.ps1")

# Now run the configurations
$all = @(   'Vim.ps1', 
            'PowerShell.ps1', 
            'UnixTools.ps1',
            'git.ps1')

foreach ( $cur in $all ) {
    write-host "Running $cur"
    & (".\" + $cur) | %{ write-host ("`t{0}" -f $_) } 
}

