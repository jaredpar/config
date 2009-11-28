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

#==============================================================================
# Functions 
#==============================================================================

# Load snapin's if they are available
function Jsh.Load-Snapin([string]$name) {
    $list = @( get-pssnapin | ? { $_.Name -eq $name })
    if ( $list.Length -gt 0 ) {
        return; 
    }

    $snapin = get-pssnapin -registered | ? { $_.Name -eq $name }
    if ( $snapin -ne $null ) {
        add-pssnapin $name
    }
}


function Jsh.Push-Path([string] $location) { 
    go $location $true 
}

function Jsh.Go-Path([string] $location, [bool]$push = $false) {
    if ( $location -eq "" ) {
        write-output $Jsh.GoMap
    } elseif ( $Jsh.GoMap.ContainsKey($location) ) {
        if ( $push ) {
            push-location $Jsh.GoMap[$location]
        } else {
            set-location $Jsh.GoMap[$location]
        }
    } elseif ( test-path $location ) {
        if ( $push ) {
            push-location $location
        } else {
            set-location $location
        }
    } else {
        write-output "$loctaion is not a valid go location"
        write-output "Current defined locations"
        write-output $Jsh.GoMap
    }
}

function Jsh.Run-Script([string] $name) {
    if ( $Jsh.ScriptMap.ContainsKey($name) ) {
        . $Jsh.ScriptMap[$name]
    } else {
        write-output "$name is not a valid script location"
        write-output $Jsh.ScriptMap
    }
}


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

#==============================================================================

#==============================================================================
# Alias 
#==============================================================================
set-alias gcid      Get-ChildItemDirectory
set-alias wget      Get-WebItem
set-alias ss        select-string
set-alias ssr       Select-StringRecurse 
set-alias go        Jsh.Go-Path
set-alias gop       Jsh.Push-Path
set-alias script    Jsh.Run-Script
set-alias ia        Invoke-Admin
set-alias ica       Invoke-CommandAdmin
set-alias isa       Invoke-ScriptAdmin
#==============================================================================

pushd $Jsh.ScriptPath

# Setup the go locations
$Jsh.GoMap["ps"]        = $Jsh.ScriptPath
$Jsh.GoMap["config"]    = $Jsh.ConfigPath
$Jsh.GoMap["~"]         = "~"

# Setup load locations
$Jsh.ScriptMap["profile"]       = join-path $Jsh.ScriptPath "Profile.ps1"
$Jsh.ScriptMap["common"]        = $(join-path $Jsh.ScriptPath "LibraryCommon.ps1")
$Jsh.ScriptMap["viemu"]         = $(join-path $Jsh.ScriptPath "LibraryViEmu.ps1")
$Jsh.ScriptMap["svn"]           = $(join-path $Jsh.ScriptPath "LibrarySubversion.ps1")
$Jsh.ScriptMap["subversion"]    = $(join-path $Jsh.ScriptPath "LibrarySubversion.ps1")
$Jsh.ScriptMap["favorites"]     = $(join-path $Jsh.ScriptPath "LibraryFavorites.ps1")
$Jsh.ScriptMap["registry"]      = $(join-path $Jsh.ScriptPath "LibraryRegistry.ps1")
$Jsh.ScriptMap["reg"]           = $(join-path $Jsh.ScriptPath "LibraryRegistry.ps1")
$Jsh.ScriptMap["token"]         = $(join-path $Jsh.ScriptPath "LibraryTokenize.ps1")
$Jsh.ScriptMap["unit"]          = $(join-path $Jsh.ScriptPath "LibraryUnitTest.ps1")
$Jsh.ScriptMap["tfs"]           = $(join-path $Jsh.ScriptPath "LibraryTfs.ps1")
$Jsh.ScriptMap["config"]        = $(join-path $Jsh.ScriptPath "LibraryConfig.ps1")
$Jsh.ScriptMap["tab"]           = $(join-path $Jsh.ScriptPath "TabExpansion.ps1")
$Jsh.ScriptMap["cprofile"]      = $(join-path $Jsh.ScriptPath "LocalComputer\Profile.ps1")

# Load the common functions
. script common
. script config
. script tab
$global:libCommonCertPath = (join-path $Jsh.ConfigPath "Data\Certs\jaredp_code.pfx")

# Load the snapin's we want
Jsh.Load-Snapin "pscx"
Jsh.Load-Snapin "JshCmdlet" 

# Setup the Console look and feel
$host.UI.RawUI.ForegroundColor = "Yellow"
if ( Test-Admin ) {
	$title = "Administrator Shell - {0}" -f $host.UI.RawUI.WindowTitle
	$host.UI.RawUI.WindowTitle = $title;
}

# Call the computer specific profile.  If it doesn't already exist, then copy in the 
# default one
$compProfile = $Jsh.ScriptMap["cprofile"]
if ( -not (test-path $compProfile)) { 
    mkdir (split-path -parent $compProfile) | out-null
    ni $compProfile -type File | out-null 
    copy --force ComputerProfile.ps1 $compProfile
}
. script cprofile

# If the computer name is the same as the domain then we are not 
# joined to active directory
if ($env:UserDomain -ne $env:ComputerName ) {
    # Call the domain specific profile data
    write-host "Domain $env:UserDomain"
    $domainProfile = join-path $env:UserDomain "Profile.ps1"
    if ( -not (test-path $domainProfile))  { ni $domainProfile -type File | out-null }
    . ".\$domainProfile"
}

# Run the get-fortune command if JshCmdlet was loaded
if ( get-command "get-fortune" -ea SilentlyContinue ) {
    get-fortune -timeout 1000
}

# Finished with the profile, go back to the original directory
popd

