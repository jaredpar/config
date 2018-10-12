#==============================================================================
# Jared Parsons PowerShell Profile (jaredpparsons@gmail.com)
#==============================================================================
#==============================================================================

$script:scriptPath = $(split-path -parent $MyInvocation.MyCommand.Definition) 
$env:PSModulePath = (resolve-path (join-path $scriptPath "Modules")) 
import-module Common

#==============================================================================
# Functions 
#==============================================================================

# Set the prompt
function prompt() {

    if (test-wow64) {
        write-host -NoNewLine "Wow64 "
    }

    if (test-admin) { 
        write-host -NoNewLine -f red "Admin "
    }

    write-host -NoNewLine -ForegroundColor Green $(get-location)
    foreach ($entry in (get-location -stack)) {
        write-host -NoNewLine -ForegroundColor Red '+';
    }

    write-host -NoNewLine -ForegroundColor Green '>'
    ' '
}

# Setup the Console look and feel
$host.UI.RawUI.ForegroundColor = "Yellow"
if (test-admin) {
	$title = "Administrator Shell - {0}" -f $host.UI.RawUI.WindowTitle
	$host.UI.RawUI.WindowTitle = $title;
}

# Load machine specific profile if it exists
$script:machineProfile = Join-Path ${env:USERPROFILE} "machine-profile.ps1s"
if (test-path $machineProfile) {
    . $machineProfile
}
