[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
param (
  [string]$directory = $null,
  [switch]$disable = $false,
  [parameter(ValueFromRemainingArguments=$true)] $badArgs)

try {
  . (Join-Path $PSScriptRoot "..\PowerShell\Common-Utils.ps1")

  if (-not (Test-Admin)) {
    Write-Host "This script must be run from an admin console"
    exit 1
  }

  if ($null -ne $badArgs) {
    Write-Host "Unrecognized arguments: $badArgs"
    exit 1
  }

  if ("" -eq $directory) {
    Write-Host "Must provide a dump directory"
    exit 1
  }

  if (-not $disable) {
    & reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /f
    & reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /f /v DumpType /t REG_DWORD /d 2
    & reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /f /v DumpCount /t REG_DWORD /d 2
    & reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /f /v DumpFolder /t REG_SZ /d $directory
  }
  else {
    & reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" 
  }

  exit 0
}
catch {
  Write-Host $_
  Write-Host $_.Exception
  Write-Host $_.ScriptStackTrace
  exit 1
}
finally {
  Pop-Location
}
