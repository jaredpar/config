
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
[CmdletBinding(PositionalBinding=$false)]
param ()

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

try {
  . (Join-Path $PSScriptRoot "Common-Utils.ps1")

  Exec-Command "git" "fetch"
  Exec-Command "git" "merge origin/main --ff-only"
  Exec-Command "pwsh" $(Join-Path $PSScriptRoot "Go.ps1")

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
