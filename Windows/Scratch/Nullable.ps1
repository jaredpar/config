
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
param (
  [string]$directory = $null,
  [switch]$showMissing = $false,
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

function Get-All([string]$directory) {
  $localFileCount = 0;
  $localEnabledCount = 0;
  $missing = @()
  foreach ($file in Get-ChildItem $directory | ?{ -not $_.PSIsContainer }) {
    $localFileCount++
    if (Test-Nullable $file.FullName) {
      $localEnabledCount++
    }
    else {
      $missing += $file.FullName
    }
  }

  $children = @()
  $childFileCount = 0;
  $childEnabledCount = 0;
  foreach ($childDirectory in Get-ChildItem $directory | ?{ $_.PSIsContainer}) {
    $child = Get-All $childDirectory.FullName
    $children += $child
    $childFileCount += $child.TotalFileCount
    $childEnabledCount += $child.TotalEnabledCount
    $missing += $child.Missing
  }

  $name = Split-Path -Leaf $directory
  return @{
    Name = $name;
    Children = $children;
    LocalFileCount = $localFileCount;
    LocalEnableCount = $localEnabledCount;
    TotalFileCount = $localFileCount + $childFileCount;
    TotalEnabledCount = $localEnabledCount + $childEnabledCount;
    Missing = $missing
  }
}

function Print-All($node, [string]$indent) {
  $name = $node.Name;
  $localFile = $node.LocalFileCount;
  $localEnabled = $node.LocalEnableCount;
  $totalFile = $node.TotalFileCount
  $totalEnabled = $node.totalEnabledCount;

  if ($node.Children.Count -eq 0) {
    Write-Host "$($indent)$name ($localEnabled/$localFile)"
  }
  else {
    Write-Host "$($indent)$name ($localEnabled/$localFile) ($totalEnabled/$totalFile)"
    foreach ($child in $node.Children) {
      Print-All $child ($indent + "  ")
    }
  }
}

try {
  . (Join-Path $PSScriptRoot "..\PowerShell\Common-Utils.ps1")

  $node = Get-All $directory
  Print-All $node ""

  if ($showMissing) {
    Write-Host "Missing"
    foreach ($file in $node.Missing) {
      Write-Host $file
    }
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
