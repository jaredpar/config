
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

# Run all of the admin configuration scripts.  Do this as a separate script
# so we can elevate here
$psi = new-object "Diagnostics.ProcessStartInfo"
$psi.FileName = $psExe
$psi.Arguments = "-File " + $(join-path $scriptPath "ConfigureAdmin.ps1")
$psi.Verb = "runas"
$proc = [Diagnostics.Process]::Start($psi)
$proc.WaitForExit();

# Now run the standard configuration scripts
. $(join-path $scriptPath "..\Powershell\Profile.ps1")
import-module configuration
repair-configuration

