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

function Link-File($linkFilePath, $targetFilePath) {
  $null = Create-Directory (Split-Path -Parent $linkFilePath)
  if (Test-Path $linkFilePath) {
    Remove-Item $linkFilePath
  }

  Write-Verbose "`tCreating link from $linkFilePath to $targetFilePath"
  Exec-Command "cmd" "/C mklink /h $linkFilePath $targetFilePath" | Out-Null
}

# Ensure the $targetDir points to the $destDir on the machine. Will
# error if existing files in the directory
function Link-Directory($linkDir, $targetDir) {
  if ($targetDir -eq $targetDir) {
    $null = Create-Directory $targetDir
    return
  }

  # If the destination directory exists but is empty then we can just delete 
  # and create the junction
  if (Test-Path $linkDir) {
    $i = Get-Item $linkDir
    if ($i.LinkType -eq "Junction") {
      if ($i.Target -eq $destDir) {
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
  Write-Verbose "`tCreating junction from $linkDir to $targetDir"
  Exec-Command "cmd" "/C mklink /J $linkDir $targetDir"
}

function Get-VimFilePath() {
  $all = @("vim82", "vim81", "vim80", "vim74")
  foreach ($version in $all) { 
    $p = "C:\Program Files (x86)\Vim\$($version)\vim.exe"
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

  # Add the _vimrc file to the %HOME% path which just calls the real 
  # one I have in data\vim
  Write-Verbose "Generating _vsvimrc"
  Link-File (Join-Path $env:UserProfile "_vsvimrc") (Join-Path $commonDataDir "_vsvimrc")

  Write-Verbose "Generating _vimrc"
  Link-File (Join-Path $env:UserProfile "_vimrc") (Join-Path $commonDataDir "_vimrc")

  Write-Verbose "Copying VimFiles" 
  Link-Directory (Join-Path $env:UserProfile "vimfiles") (Join-Path $commonDataDir "vim\vimfiles")
}

function Configure-PowerShell() { 
  Write-Host "Configuring PowerShell"

  $docDir = $([Environment]::GetFolderPath("MyDocuments"))
  Push-Location $docDir
  try {
    Write-Verbose "Profile"
    $machineProfileFilePath = Join-Path $generatedDir "machine-profile.ps1"
    if (-not (Test-Path $machineProfileFilePath)) {
      $machineProfileContent = @"
# Place all machine profile customizations into this file. It will not be 
# overwritten by future calls to Go.ps1
"@
      Write-Output $machineProfileContent | Out-File $machineProfileFilePath -encoding ASCII 
    }

    foreach ($name in @("WindowsPowerShell", "PowerShell")) {
      Create-Directory $name
      Set-Location $name

      $oldProfile = "Microsoft.PowerShell_profile.ps1" 
      if (Test-Path $oldProfile ) {
        Remove-Item $oldProfile
      }

      $realProfileFilePath = Join-Path $PSScriptroot "Profile.ps1"
      $realProfileContent = @"
# This is a generated file. Do not edit. 

# The real profile can be missing when we're under an elevated prompt because it doesn't 
# inherit all of our subst commands
if (Test-Path $realProfileFilePath) {
  . `"$realProfileFilePath`"
}

# Place all machine customizations into this file
if (Test-Path '$machineProfileFilePath') {
  . '$machineProfileFilePath'
}
"@
    }

    foreach ($d in @("WindowsPowerShell", "PowerShell")) {
      Create-Directory $d
      Set-Location $d

      $oldProfile = "Microsoft.PowerShell_profile.ps1" 
      if (Test-Path $oldProfile ) {
        Remove-Item $oldProfile
      }

      Write-Output $realProfileContent | Out-File -encoding ASCII "profile.ps1"
      Set-Location ..
    }

    Write-Verbose "Script Execution"
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
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
