
Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

function Install-App([string]$appName, [string]$id) {

  Write-Host "Installing $appName with id $id"
  $t = Exec-CommandRaw "winget" "list --id $id"
  if ($t.ExitCode -eq 0) {
    Write-Host "$appName is already installed"
    return
  }

  Exec-Console "winget" "install --id $id"
}

try {
  . (Join-Path $PSScriptRoot "Common-Utils.ps1")
  Push-Location $PSScriptRoot

  Install-App "ILSpy" "icsharpcode.ILSpy"
  Install-App "Vim" "vim.vim"
  Install-App "PerfView" "Microsoft.PerfView"

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
