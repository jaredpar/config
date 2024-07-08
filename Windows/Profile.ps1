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
    $text += "⚡🔨"
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

# Make it so ~ expansion works in a sane way until the 7.4.0 behavior 
# is resolved
# https://github.com/PowerShell/PowerShell/issues/20750
function code() {
    if ($args.Length -gt 0) {
        $p = Resolve-Path $args[0]
        & code.cmd $p ($args[1..$args.Length] -join " ")
    }
    else {
        & code.cmd
    }
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

switch ($env:COMPUTERNAME) {
    'PARANOID2' {
        Set-Alias msbuild 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe'
    }
    'CPC-jared-P2WJZ' {
        Set-Alias msbuild 'C:\Program Files\Microsoft Visual Studio\2022\Main\MSBuild\Current\Bin\MSBuild.exe'
        Set-Alias msbuildp 'C:\Program Files\Microsoft Visual Studio\2022\Preview\MSBuild\Current\Bin\MSBuild.exe'
    }
    default {
        Write-Host "No computer specific profile"
    }
}
