#==============================================================================
# Jared Parsons PowerShell Profile (jaredpparsons@gmail.com)
#==============================================================================

#==============================================================================
# Common Variables Start
#==============================================================================
$global:Jsh = new-object psobject 
$Jsh | add-member NoteProperty "ScriptPath" $(split-path -parent $MyInvocation.MyCommand.Definition) 
$Jsh | add-member NoteProperty "ConfigPath" $(split-path -parent $Jsh.ScriptPath)
$Jsh | add-member NoteProperty "UtilsRawPath" $(join-path $Jsh.ConfigPath "Utils")
$Jsh | add-member NoteProperty "UtilsPath" $(join-path $Jsh.UtilsRawPath $env:PROCESSOR_ARCHITECTURE)
$Jsh | add-member NoteProperty "GoMap" @{}
$Jsh | add-member NoteProperty "ScriptMap" @{}
$Jsh | add-member NoteProperty "IsTestMachine" $false

#==============================================================================

$script:scriptPath = $(split-path -parent $MyInvocation.MyCommand.Definition) 
$env:PSModulePath = $env:PSModulePath = (resolve-path (join-path $scriptPath "Modules")) 
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

# If the computer name is the same as the domain then we are not 
# joined to active directory
if ($env:UserDomain -eq "Redmond" ) { 
    import-module Redmond
}

