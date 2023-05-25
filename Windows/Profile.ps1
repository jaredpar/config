#==============================================================================
# Jared Parsons PowerShell Profile (jaredpparsons@gmail.com)
#==============================================================================
#==============================================================================

. (Join-Path $PSScriptRoot "Common-Utils.ps1")

#==============================================================================
# Functions 
#==============================================================================

# Set the prompt
function prompt() {

    if ($PSVersionTable.PSEdition -ne 'Core') {
        $text = "$(Get-Location)> "
        return $text
    }

    $text = ""
    if (([IntPtr]::size -eq 4) -and (Test-Path env:\PROCESSOR_ARCHITEW6432)) {
        $text += "Wow64 "
    }

    if (Test-Admin) { 
        $text += "`e[34mAdmin `e[0m"
    }

    $text += "`e[32m"
    $text += $(Get-Location)
    $text += "`e[0m"
    $stack = Get-Location -stack
    if ($stack) {
        $text += " `e[34m"
        foreach ($entry in (Get-Location -stack)) {
            $text += '+';
        }
        $text += "`e[0m"
    }

    # $text += "`e[1e`e[1d"
    $text += "`n"
    $text += "🍿🐻"
    $text += " `e[34m> `e[0m"
    $text
}

function Set-LocationParent() {
    Set-Location ..
}

function Set-LocationGrandParent() {
    Set-Location ..
    Set-Location ..
}

# Setup the Console look and feel
$host.UI.RawUI.ForegroundColor = "Yellow"
if (Test-Admin) {
	$title = "Administrator Shell - {0}" -f $host.UI.RawUI.WindowTitle
	$host.UI.RawUI.WindowTitle = $title;
}

Set-Alias ss Select-String
Set-Alias ssr Select-StringRecurse
Set-Alias .. Set-LocationParent
Set-Alias ... Set-LocationGrandParent

# Load machine specific customizations. Any customization which is machine specific 
# should go into this file as it's not tracked in Git
$script:machineProfileFilePath = Join-Path $PSScriptRoot "Local\machine-profile.ps1"
if (-not (Test-Path $machineProfileFilePath)) {
    $machineProfileContent = "# Machine specific profile code"
    Write-Output $machineProfileContent | Out-File $machineProfileFilePath -encoding ASCII 
} else {
    . $machineProfileFilePath
}

