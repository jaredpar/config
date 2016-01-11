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

    if ( Test-Wow64 ) {
        write-host -NoNewLine "Wow64 "
    }

    if ( Test-Admin ) { 
        write-host -NoNewLine -f red "Admin "
    }

	  write-host -NoNewLine -ForegroundColor Green $(get-location)
    foreach ( $entry in (get-location -stack)) {
        write-host -NoNewLine -ForegroundColor Red '+';
    }

    write-host -NoNewLine -ForegroundColor Green '>'
    ' '
}

# Setup the Console look and feel
$host.UI.RawUI.ForegroundColor = "Yellow"
if ( Test-Admin ) {
	$title = "Administrator Shell - {0}" -f $host.UI.RawUI.WindowTitle
	$host.UI.RawUI.WindowTitle = $title;
}

