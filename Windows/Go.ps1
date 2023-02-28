#####
#
# Configure the Windows environment based on the script contents
#
####
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
[CmdletBinding(PositionalBinding=$false)]
param (
  [parameter(ValueFromRemainingArguments=$true)] $badArgs)

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

function Write-HostWarning([string]$message) {
  Write-Host -ForegroundColor Yellow "WARN: $message"
}

function Write-HostError([string]$message) {
  Write-Host -ForegroundColor Red "ERROR: $message"
}

# Ensure that $linkFilePath refers to $targetFilePath as a symlink
function Link-File($linkFilePath, $targetFilePath) {
  Write-Verbose "Creating link from $linkFilePath to $targetFilePath"
  $null = Create-Directory (Split-Path -Parent $linkFilePath)
  if (Test-Path $linkFilePath) {
    Remove-Item $linkFilePath
  }

  Exec-Command "cmd" "/C mklink /h $linkFilePath $targetFilePath" | Out-Null
}

# Ensure that $linkDir refers to $targetDir on the machine. If it is 
# not the same path then a junction will be created from $linkDir to
# $targetDir
function Link-Directory([string]$linkDir, [string]$targetDir) {
  Write-Verbose "Creating junction from $linkDir to $targetDir"
  if ($linkDir -eq $targetDir) {
    Write-Verbose "Link is same as target so no junction needed"
    $null = Create-Directory $targetDir
    return
  }

  # If the destination directory exists but is empty then we can just delete 
  # and create the junction
  if (Test-Path $linkDir) {
    $i = Get-Item $linkDir
    if ($i.LinkType -eq "Junction") {
      if ($i.Target -eq $targetDir) {
        return
      }

      Write-HostError "Junction $linkDir points to wrong source directory: $($i.Target)"
      return
    }

    $c = @(Get-ChildItem $linkDir).Length
    if ($c -eq 0) {
      Write-Verbose "Removing old empty directory"
      Remove-Item $linkDir  
    }
    else {
      Write-HostError "Junction source directory not empty: $linkDir"
      return
    }
  }

  $null = Create-Directory (Split-Path -Parent $linkDir)
  Exec-Command "cmd" "/C mklink /J $linkDir $targetDir"
}

function Get-VimFilePath() {
  $all = @("vim82", "vim81", "vim80", "vim74")
  foreach ($version in $all) { 
    $p = "C:\Program Files (x86)\Vim\$($version)\vim.exe"
    if (Test-Path $p) { 
        return $p
    }

    $p = "C:\Program Files\Vim\$($version)\vim.exe"
    if (Test-Path $p) { 
        return $p
    }
  }

  return $null
}

function Get-GitFilePath() { 
  $g = Get-Command "git" -ErrorAction SilentlyContinue
  if ($null -eq $g) { 
    return $null
  }

  return $g.Path
}

# Configure both the vim and vsvim setup
function Configure-Vim() { 
  if ($null -eq $vimFilePath) {
    Write-Host "SKIP vim configuration"
    return
  }

  Write-Host "Configuring Vim"
  Write-Verbose "Location: `"$vimFilePath`""

  Link-File (Join-Path $env:UserProfile "_vsvimrc") (Join-Path $commonDataDir "_vsvimrc")
  Link-File (Join-Path $env:UserProfile "_vimrc") (Join-Path $commonDataDir "_vimrc")
  Link-Directory (Join-Path $env:UserProfile "vimfiles") (Join-Path $commonDataDir "vim\vimfiles")
}

function Configure-PowerShell() { 
  Write-Host "Configuring PowerShell"

  $docDir = $([Environment]::GetFolderPath("MyDocuments"))
  Push-Location $docDir
  try {
    Write-Verbose "Profile"
    $realProfileFilePath = Join-Path $PSScriptroot "Profile.ps1"

    foreach ($dirName in @("WindowsPowerShell", "PowerShell")) {
      Create-Directory $dirName
      Set-Location $dirName
      $profileContent = @"
# This is a generated file. Do not edit. 
. `"$realProfileFilePath`"
"@

      Write-Output $profileContent | Out-File -encoding ASCII "profile.ps1"
      Set-Location ..
    }

    Write-Verbose "Pwsh Script Execution"
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    Write-Verbose "Powershell Script Execution"
    Exec-Console "powershell" "-NoProfile Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -softFail
  }
  finally {
    Pop-Location
  }
}

function Configure-Git() { 
  if ($null -eq $gitFilePath) {
    Write-Verbose "Skip git configuration because git isn't installed"
    return
  }

  Write-Host "Configuring Git"
  Write-Verbose "Location: $gitFilePath"

  Write-Verbose "Standard Setup"
  $gitEditor = if ($null -ne $vimFilePath) { $vimFilePath } else { "notepad.exe" }
  Exec-Console $gitFilePath "config --global core.editor `"'$gitEditor'`""
  Exec-Console $gitFilePath "config --global core.longpaths true"
  Exec-Console $gitFilePath "config --global user.name `"Jared Parsons`""
  Exec-Console $gitFilePath "config --global user.email `"jaredpparsons@gmail.com`""
  Exec-Console $gitFilePath "config --global fetch.prune true"
  Exec-Console $gitFilePath "config --global push.default current"
  Exec-Console $gitFilePath "config --global commit.gpgsign false"
}

function Configure-Terminal() {
  Write-Host "Configuring Terminal"

  $linkFilePath = Join-Path ${env:LOCALAPPDATA} "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" 
  if (Test-Path $linkFilePath) {
    Link-File $linkFilePath (Join-Path $dataDir "terminal-settings.json")
  }
  else {
    Write-Host "Did not find windows terminal"
  }
}

function Configure-Winget() {
  Write-Host "Configuring winget"
  $wingetDir = Join-Path ${env:LOCALAPPDATA} "Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
  $linkFilePath = Join-Path $wingetDir "settings.json"
  if (Test-Path $wingetDir) {
    Link-File $linkFilePath (Join-Path $dataDir "winget-settings.json")
  }
  else {
    Write-Host "Did not find winget"
  }
}

# The goal of this function is to ensure that standard directories, like 
# code, tools or nuget, is in the same location on every machine. If the 
# real directories differ then create a junction to make it real
function Configure-Junctions() {
  Link-Directory $codeDir $script:settings.codeDir
  Link-Directory $nugetDir $script:settings.nugetDir
  Link-Directory $toolsDir $script:settings.toolsDir
}

# This will update the snapshot in the OneDrive Config folder if OneDrive is syncing on
# this machine.
function Configure-Snapshot() {
  if (-not $isRunFromGit) {
    Write-Verbose "Not configuring snapshot because not running from Git"
  }

  Write-Host "Configuring OneDrive Snapshot"

  $oneDriveDir = Join-Path ${env:USERPROFILE} "OneDrive\Config"
  if (-not (Test-Path $oneDriveDir)) {
    Write-HostWarning "OneDrive not available at $oneDriveDir"
    return
  }

  $snapshotDir = Join-Path $oneDriveDir "Snapshot"
  Create-Directory $snapshotDir

  & robocopy "$repoDir" "$snapshotDir" /E /PURGE /XD ".git" | Out-Null
}

function Load-Settings() {
  $realCodeDir = $codeDir
  $realNuGetDir = $nugetDir
  $realToolsDir = Join-Path ${env:USERPROFILE} "OneDrive\Config\Tools"

  # When running as a snapshot the Tools directory will be a sibling of the current 
  # directory.
  if (-not (Test-Path $realToolsDir)) {
    $realToolsDir = Split-Path -Parent $PSScriptRoot
    $realToolsDir = Split-Path -Parent $realToolsDir
    $realToolsDir = Join-Path $realToolsDir "Tools"

    if (-not (Test-Path $realToolsDir)) {
      $realToolsDir = Join-Path ${env:USERPROFILE} "Tools"
      Write-HostWarning "Can't find any tools directory using empty $realToolsDir"
      Create-Directory $realToolsDir
    }
  }

  switch -Wildcard ("${env:COMPUTERNAME}\${env:USERNAME}") {
    "JAREDPAR05\*" { 
      $realCodeDir = "e:\code"
      $realNuGetDir = "e:\nuget"
      break;
    }
    "JAREDPAR06\*" { 
      $realCodeDir = "e:\code"
      $realNuGetDir = "e:\nuget"
      break;
    }
    default { }
  }

  $script:settings = @{
    codeDir = $realCodeDir
    nugetDir = $realNugetDir
    toolsDir = $realToolsDir
  }
}

try {
  . (Join-Path $PSScriptRoot "Common-Utils.ps1")
  Push-Location $PSScriptRoot

  if ($null -ne $badArgs) {
    Write-Host "Unsupported argument $badArgs"
    Print-Usage
    exit 1
  }

  # Setup the directories referenced in the script
  $codeDir = Join-Path ${env:USERPROFILE} "code";
  $nugetDir = Join-Path ${env:USERPROFILE} ".nuget";
  $toolsDir = Join-Path ${env:USERPROFILE} "tools";
  $repoDir = Split-Path -parent $PSScriptRoot
  $commonDataDir = Join-Path $repoDir "CommonData"
  $dataDir = Join-Path $PSScriptRoot "Data"
  $isRunFromGit = Test-Path (Join-Path $repoDir ".git")
  $generatedDir = Join-Path $PSScriptRoot "Generated"
  Create-Directory $generatedDir

  Load-Settings
  Write-Host "Data Source Directories"
  Write-Host "`tCode Directory: $($settings.codeDir)"
  Write-Host "`tNuget Directory: $($settings.nugetDir)"
  Write-Host "`tTools Directory: $($settings.toolsDir)"

  $vimFilePath = Get-VimFilePath
  $gitFilePath = Get-GitFilePath

  Configure-Junctions
  Configure-Vim
  Configure-PowerShell
  Configure-Git
  Configure-Terminal
  Configure-Winget
  Configure-Snapshot

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
