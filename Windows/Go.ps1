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
  Exec-Console $gitFilePath "config --global push.default current"
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

# The goal of this function is to ensure that standard directories, like 
# code, tools or nuget, is in the same location on every machine. If the 
# real directories differ then create a junction to make it real
function Configure-Junctions() {
  function Configure-One($junctionDir, $realDir) {
    if ($junctionDir -eq $realDir) {
      $null = Create-Directory $junctionDir
      return
    }

    # If the destination directory exists but is empty then we can just delete 
    # and create the junction
    if (Test-Path $junctionDir) {
      $i = Get-Item $junctionDir
      if ($i.LinkType -eq "Junction") {
        if ($i.Target -eq $realDir) {
          return
        }

        Write-HostError "Junction $junctionDir points to wrong source directory: $($i.Target)"
        return
      }

      $c = @(Get-ChildItem $junctionDir).Length
      if ($c -eq 0) {
        Remove-Item $junctionDir  
      }
      else {
        Write-HostError "Junction source directory not empty: $junctionDir"
        return
      }
    }

    Write-Host "`tCreating junction from $junctionDir to $realDir"
    Exec-Command "cmd" "/C mklink /J $junctionDir $realDir"
  }

  Configure-One $codeDir $script:settings.codeDir
  Configure-One $nugetDir $script:settings.nugetDir
  Configure-One $toolsDir $script:settings.toolsDir
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

# Delete legacy settings and infra
function Configure-Legacy() {
  Write-Host "Configuring Legacy Items"

  if (($env:NUGET_PACKAGES -ne $null) -and (Test-Path $env:NUGET_PACKAGES)) {
    Remove-Item env:\NUGET_PACKAGES
    Exec-Console "setx" 'NUGET_PACKAGES ""'
  }

  $shortcutFilePath = Join-Path ${env:USERPROFILE} "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startup.lnk"
  if (Test-Path $shortcutFilePath) {
    Remove-Item $shortcutFilePath
  }

  if (Test-Path "p:\") {
    Exec-Console "subst" "p: /D"
  }

  if (Test-Path "t:\") {
    Exec-Console "subst" "t: /D"
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
  Configure-VSCode
  Configure-Terminal
  Configure-Snapshot
  Configure-Legacy

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
