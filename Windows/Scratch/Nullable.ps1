
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
param (
  [string]$directory = $null,
  [parameter(ValueFromRemainingArguments=$true)] $badArgs)

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

function Test-Nullable([string]$filePath) {
  $lines = Get-Content $filePath
  $found = $false
  foreach ($line in $lines) {
    if ($line.Length -eq 0 -or $line -match "^//.*" -or $line -match "^\s+") {
      continue;
    }

    if ($line -match "#nullable enable") {
      $found = $true;
      break;
    }

    break;
  }

  return $found
}

function Print-All([string]$directory, [string]$indent) {
  $fileCount = 0;
  $enableCount = 0;

  foreach ($file in Get-ChildItem $directory | ?{ -not $_.PSIsContainer }) {
    $fileCount++
    if (Test-Nullable $file.FullName) {
      $enableCount++
    }
  }

  $name = Split-Path -Leaf $directory
  Write-Host "$($indent)$name $enableCount/$fileCount"

  foreach ($childDirectory in Get-ChildItem $directory | ?{ $_.PSIsContainer}) {
    Print-All $childDirectory.FullName ($indent + "  ")
  }
}

try {
  . (Join-Path $PSScriptRoot "..\PowerShell\Common-Utils.ps1")

  Print-All $directory
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
