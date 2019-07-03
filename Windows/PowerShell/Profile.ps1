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

    if (([IntPtr]::size -eq 4) -and (test-path env:\PROCESSOR_ARCHITEW6432)) {
        Write-Host -NoNewLine "Wow64 "
    }

    if (Test-Admin) { 
        Write-Host -NoNewLine -f red "Admin "
    }

    Write-Host -NoNewLine -ForegroundColor Green $(get-location)
    foreach ($entry in (Get-Location -stack)) {
        Write-Host -NoNewLine -ForegroundColor Red '+';
    }

    Write-Host -NoNewLine -ForegroundColor Green '>'
    ' '
}

# Setup the Console look and feel
$host.UI.RawUI.ForegroundColor = "Yellow"
if (Test-Admin) {
	$title = "Administrator Shell - {0}" -f $host.UI.RawUI.WindowTitle
	$host.UI.RawUI.WindowTitle = $title;
}

Set-Alias ss Select-String
Set-Alias ssr Select-StringRecurse
