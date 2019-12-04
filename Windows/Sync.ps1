
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
[CmdletBinding(PositionalBinding=$false)]
param ()

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

try {
  . (Join-Path $PSScriptRoot "PowerShell\Common-Utils.ps1")

  Exec-Command "git" "fetch"
  Exec-Command "git" "merge origin/master --ff-only"
  Exec-Script (Join-Path $PSScriptRoot "Go.ps1")

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
