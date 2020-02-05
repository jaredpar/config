#####
#
# Configure the Windows environment based on the script contents
#
####
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
[CmdletBinding(PositionalBinding=$false)]
param (
  [switch]$latest = $false,
  [switch]$refreshMachine = $false,
  [switch]$refreshConfig = $false,
  [parameter(ValueFromRemainingArguments=$true)] $badArgs)

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

function Write-HostWarning([string]$message) {
  Write-Host -ForegroundColor Yellow "WARN: $message"
}

function Write-HostError([string]$message) {
  Write-Host -ForegroundColor Yellow "ERROR: $message"
}

# Copy a configuration file from this repository into a location on
# the machine that is outside this repository. This will warn if the 
# destination file exists but has different content. Makes it so I 
# don't silently erase changes.
function Copy-ConfigFile($sourceFilePath, $destFilePath) {
  if (-not $refreshMachine -and (Test-Path $destFilePath)) {
    $destHash = (Get-FileHash -Path $destFilePath -Algorithm SHA256).Hash
    $sourceHash = (Get-FileHash -Path $sourceFilePath -Algorithm SHA256).Hash
    if ($destHash -ne $sourceHash) {
      if ($refreshConfig) {
        Copy-Item $destFilePath $sourceFilePath
      }
      else {
        Write-HostWarning "Can't copy $sourceFilePath to $destFilePath as there are changes in the destination"
        Write-HostWarning "`tSource hash: $sourceHash"
        Write-HostWarning "`tDestination hash: $destHash"
        Exec-CommandCore "cmd" "/c fc /l `"$destFilePath`" `"$sourceFilePath`"" -checkFailure:$false -useConsole:$true
        Write-HostWarning "Use -refreshMachine option to update machine copy"
        Write-HostWarning "Use -refreshConfig option to update checked in copy"
        return
      }
    }
  }

  Create-Directory (Split-Path -Parent $destFilePath)
  Copy-Item $sourceFilePath $destFilePath -force
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

function Get-ToolsDir() {
  # When running from Git then the Tools directory isn't in a sibling directory to the 
  # configuration scripts. Can only come from a OneDrive installation
  if ($isRunFromGit) {
    $toolsDir = Join-Path ${env:USERPROFILE} "OneDrive\Config\Tools"
  }
  else {
    $toolsDir = Split-Path -Parent $PSScriptRoot
    $toolsDir = Split-Path -Parent $toolsDir
    $toolsDir = Join-Path $toolsDir "Tools"
  }

  if (Test-Path $toolsDir) {
    return $toolsDir
  }
  else {
    return $null    
  }
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
  $realFilePath = Join-Path $commonDataDir "_vsvimrc"
  $destFilePath = Join-Path $env:UserProfile "_vsvimrc"
  Write-Output ":source $realFilePath" | Out-File -encoding ASCII $destFilePath

  Write-Verbose "Generating _vimrc"
  $realFilePath = Join-Path $commonDataDir "_vimrc"
  $destFilePath = Join-Path $env:UserProfile "_vimrc"
  Write-Output ":source $realFilePath" | Out-File -encoding ASCII $destFilePath

  Write-Verbose "Copying VimFiles" 
  $sourceDir = Join-Path $commonDataDir "vim\vimfiles"
  Copy-Item -re -fo $sourceDir $env:UserProfile
}

function Configure-PowerShell() { 
  Write-Host "Configuring PowerShell"

  $docDir = $([Environment]::GetFolderPath("MyDocuments"))
  Push-Location $docDir
  try {
    Write-Verbose "Profile"
    Create-Directory "WindowsPowerShell"
    Set-Location "WindowsPowerShell"

    $oldProfile = "Microsoft.PowerShell_profile.ps1" 
    if (Test-Path $oldProfile ) {
      Remove-Item $oldProfile
    }

    $machineProfileFilePath = Join-Path $generatedDir "machine-profile.ps1"
    if (-not (Test-Path $machineProfileFilePath)) {
      $machineProfileContent = @"
# Place all machine profile customizations into this file. It will not be 
# overwritten by future calls to Go.ps1
"@
      Write-Output $machineProfileContent | Out-File $machineProfileFilePath -encoding ASCII 
    }

    $realProfileFilePath = Join-Path $PSScriptroot "PowerShell\Profile.ps1"
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
    Write-Output $realProfileContent | Out-File -encoding ASCII "profile.ps1"
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
  Exec-Console $gitFilePath "config --global commit.gpgsign false"
}

function Configure-VSCode() { 
  Write-Host "Configuring VS Code"

  $settingsFilePath = Join-Path $dataDir "settings.json"
  $content = Get-Content -Raw $settingsFilePath
  $content = "// Actual settings file stored at: $settingsFilePath" + [Environment]::NewLine + $content
  $destFilePath = Join-Path ${env:APPDATA} "Code\User\settings.json"
  Copy-ConfigFile $settingsFilePath $destFilePath

  $keybindingsFilePath = Join-Path $dataDir "keybindings.json"
  $destFilePath = Join-Path ${env:APPDATA} "Code\User\keybindings.json"
  Copy-ConfigFile $keyBindingsFilePath $destFilePath

}

function Configure-Terminal() {
  Write-Host "Configuring Terminal"

  $destFilePath = Join-Path ${env:LOCALAPPDATA} "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\profiles.json" 
  if (Test-Path $destFilePath) {
      $profileFilePath = Join-Path $dataDir "profiles.json"
      Copy-ConfigFile $profileFilePath $destFilePath
  }
}

# Ensure that p:\nuget is setup as the package cache for the machine.
function Configure-NuGet() {
  Write-Host "Configuring NuGet cache"
  $cacheDir = "p:\nuget"
  $value = Get-ChildItem env:NUGET_PACKAGES -ErrorAction SilentlyContinue
  if ($value -ne $cacheDir)
  {
      $null = & setx NUGET_PACKAGES $cacheDir 
      $env:NUGET_PACKAGES = $cacheDir
  }
}

# The goal of this function is to ensure the following drive mappings exist at this moment and 
# whenever logging onto the machine
#   p:\ - root git enlistment for my projects
#   t:\ - tools directory 
function Configure-Drive() {
  Write-Host "Configuring Drives"

  $startupContent = @"
@echo off
REM This is a generated file. Do not edit. Instead put machine customizations into 
REM $PSCommandPath

"@

  $codeDir = switch (${env:COMPUTERNAME}) {
    "JAREDPAR05" { "e:\code" }
    "JAREDPAR06" { "e:\code" }
    default { Join-Path ${env:USERPROFILE} "code" }
  }

  if (Test-Path $codeDir) {
    if (-not (Test-Path "p:\")) {
      Exec-Command "c:\windows\system32\subst.exe" "p: $codeDir"
    }

    $startupContent += "subst p: $codeDir"
    $startupContent += [Environment]::NewLine
  }
  else {
    Write-HostWarning "$codeDir does not exist"
  }

  if ($null -ne $toolsDir) {
    if (-not (Test-Path "t:\")) {
      Exec-Command "c:\windows\system32\subst.exe" "t: $toolsDir"
    }

    $startupContent += "subst t: $toolsDir"
    $startupContent += [Environment]::NewLine
  }
  else {
    Write-HostWarning "Could not locate a Tools directory"
  }

  $startupFilePath = Join-Path $generatedDir "startup.cmd"
  $shortcutFilePath = Join-Path ${env:USERPROFILE} "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startup.lnk"
  Write-Output $startupContent | Out-File -encoding ASCII $startupFilePath

  $objShell = New-Object -ComObject ("WScript.Shell")
  $objShortCut = $objShell.CreateShortcut($shortcutFilePath)
  $objShortCut.TargetPath = $startupFilePath
  $objShortCut.Save()
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

try {
  . (Join-Path $PSScriptRoot "PowerShell\Common-Utils.ps1")
  Push-Location $PSScriptRoot

  if ($null -ne $badArgs) {
    Write-Host "Unsupported argument $badArgs"
    Print-Usage
    exit 1
  }

  $repoDir = Split-Path -parent $PSScriptRoot
  $commonDataDir = Join-Path $repoDir "CommonData"
  $dataDir = Join-Path $PSScriptRoot "Data"
  $isRunFromGit = Test-Path (Join-Path $repoDir ".git")

  $generatedDir = Join-Path $PSScriptRoot "Generated"
  Create-Directory $generatedDir

  $vimFilePath = Get-VimFilePath
  $gitFilePath = Get-GitFilePath
  $toolsDir = Get-ToolsDir

  Configure-Drive
  Configure-Vim
  Configure-PowerShell
  Configure-Git
  Configure-VSCode
  Configure-Terminal
  Configure-NuGet
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
