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

function Ensure-EnvironmentVariable([string]$name, [string]$value)
{
  if ([System.Environment]::GetEnvironmentVariable($name) -eq $value) {
    return
  }

  Write-Host "Setting environment variable $name to $value"
  Exec-Command "setx" "$name `"$value`""
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
  $all = @("vim91", "vim90", "vim82", "vim81", "vim80", "vim74")
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
    $policy = Get-ExecutionPolicy
    if ($policy -ne "Bypass" -and $policy -ne "RemoteSigned") {
      Set-ExecutionPolicy Bypass -Scope CurrentUser
    }

    # The PSMODULEPATH must be cleared to ensure PowerShell doesn't cross contaminate pwsh and
    # vice versa. 
    Write-Verbose "Powershell Script Execution"
    Exec-Command "cmd" "/C set PSMODULEPATH=&&powershell -NoProfile -ExecutionPolicy Bypass -Command Set-ExecutionPolicy Bypass -Scope CurrentUser" -softFail
  }
  finally {
    Pop-Location
  }
}

function Configure-Git() { 
  Write-Host "Configuring Git"

  # Remove the old way where ~/.gitconfig was setup as a hard link
  $config = Join-Path $env:UserProfile ".gitconfig"
  if ((Test-Path $config) -and ((Get-Item $config).LinkType -eq "HardLink")) { 
    Remove-Item $config
  }

  & git config --global user.name "Jared Parsons"
  & git config --global user.email jared@paranoidcoding.org
  & git config --global fetch.prune true
  & git config --global core.longpaths true
  & git config --global push.default current
  & git config --global commit.gpgsign false
  & git config --global alias.assume 'update-index --assume-unchanged'
  & git config --global alias.unassume 'update-index --no-assume-unchanged'

  if ($gitEditor -ne "") {
    & git config --global core.editor $gitEditor
  }
  else {
    Write-HostWarning "No git editor configured"
  }
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

# The goal of this function is to ensure that a standard tools directory
# exists on all machines
function Configure-Tools() {
  Write-Host "Configuring Tools"
  $d = Join-Path $env:USERPROFILE "tools"
  Link-Directory $d $toolsDir
}

function Configure-NuGet() {
  Write-Host "Configuring NuGet"
  Ensure-EnvironmentVariable "NUGET_PACKAGES" $nugetDir
}

function Load-MachineSettings() {
  $localDir = Join-Path $PSScriptRoot "Local"
  $null = Create-Directory $localDir
  $machineSettingsFilePath = Join-Path $localDir "machine-settings.ps1"
  if (-not (Test-Path $machineSettingsFilePath)) {
    $content = @"
# `$script:codeDir = "$codeDir"
# `$script:nugetDir = "$nugetDir"
# `$script:toolsDir = "$toolsDir"
# `$script:gitEditor = ""
"@
    Write-Output $content | Out-File $machineSettingsFilePath -encoding ASCII 
  }

  . $machineSettingsFilePath
}

try {
  . (Join-Path $PSScriptRoot "Common-Utils.ps1")
  Push-Location $PSScriptRoot

  if ($null -ne $badArgs) {
    Write-Host "Unsupported argument $badArgs"
    Print-Usage
    exit 1
  }

  $codeDir = Join-Path ${env:USERPROFILE} "code";
  $nugetDir = Join-Path ${env:USERPROFILE} ".nuget";
  $toolsDir = Join-Path ${env:USERPROFILE} "OneDrive\Config\Tools"
  $repoDir = Split-Path -parent $PSScriptRoot
  $commonDataDir = Join-Path $repoDir "CommonData"
  $dataDir = Join-Path $PSScriptRoot "Data"
  $gitEditor = ""

  Load-MachineSettings

  Write-Host "Data Source Directories"
  Write-Host "`tCode Directory: $codeDir"
  Write-Host "`tNuget Directory: $nugetDir"
  Write-Host "`tTools Directory: $toolsDir"

  $vimFilePath = Get-VimFilePath

  Configure-Tools
  Configure-NuGet
  Configure-Vim
  Configure-PowerShell
  Configure-Git
  Configure-Terminal
  Configure-Winget

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
