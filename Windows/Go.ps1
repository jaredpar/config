#####
#
# Configure the Windows environment based on the script contents
#
####
[CmdletBinding(PositionalBinding=$false)]
param (
  [switch]$force = $false,
  [parameter(ValueFromRemainingArguments=$true)] $badArgs)

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

# Copy a configuration file from this repository into a location on
# the machine that is outside this repository. This will warn if the 
# destination file exists but has different content. Makes it so I 
# don't silently erase changes.
function Copy-ConfigFile($sourceFilePath, $destFilePath) {
  if (-not $force -and (Test-Path $destFilePath)) {
    $destHash = (Get-FileHash -Path $destFilePath -Algorithm SHA256).Hash
    $sourceHash = (Get-FileHash -Path $sourceFilePath -Algorithm SHA256).Hash
    if ($destHash -ne $sourceHash) {
      Write-Host "Can't copy $sourceFilePath to $destFilePath as there are changes in the destination"
      Write-Host "`tSource hash: $sourceHash"
      Write-Host "`tDestination hash: $destHash"
      Exec-CommandCore "cmd" "/c fc /l `"$destFilePath`" `"$sourceFilePath`"" -checkFailure:$false -useConsole:$true
      return
    }
  }

  Create-Directory (Split-Path -Parent $destFilePath)
  Copy-Item $sourceFilePath $destFilePath -force
}

function Get-VimFilePath() {
  $all = @("vim81", "vim80", "vim74")
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
  if ($g -eq $null) { 
    return $null
  }

  return $g.Path
}

function Get-GpgFilePath() {
  $gpgFilePath = "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
  if (Test-Path $gpgFilePath) { 
    return $gpgFilePath
  }

  return $null
}

# Configure both the vim and vsvim setup
function Configure-Vim() { 
  if ($vimFilePath -eq $null) {
    Write-Host "SKIP vim configuration"
    return
  }

  Write-Host "Configuring Vim"
  Write-Host "`tLocation: `"$vimFilePath`""

  Write-Host "`tGenerating _vsvimrc"
  $realFilePath = Join-Path $commonDataDir "_vsvimrc"
  $destFilePath = Join-Path $env:UserProfile "_vsvimrc"
  Write-Output ":source $realFilePath" | Out-File -encoding ASCII $destFilePath

  Write-Host "`tGenerating _vimrc"
  $realFilePath = Join-Path $commonDataDir "_vimrc"
  $destFilePath = Join-Path $env:UserProfile "_vimrc"
  Write-Output ":source $realFilePath" | Out-File -encoding ASCII $destFilePath

  Write-Host "`tCopying VimFiles" 
  $sourceDir = Join-Path $commonDataDir "vim\vimfiles"
  Copy-Item -re -fo $sourceDir $env:UserProfile
}

function Configure-PowerShell() { 
  Write-Host "Configuring PowerShell"

  $docDir = $([Environment]::GetFolderPath("MyDocuments"))
  Push-Location $docDir
  try {
    Write-Host "`tProfile"
    Create-Directory "WindowsPowerShell"
    Set-Location "WindowsPowerShell"

    $oldProfile = "Microsoft.PowerShell_profile.ps1" 
    if (Test-Path $oldProfile ) {
      Remove-Item $oldProfile
    }

    $realProfileFilePath = Join-Path $PSScriptroot "PowerShell\Profile.ps1"
    $realProfileContent = @"
# This is a generated file. Do not edit. 
. `"$realProfileFilePath`"
"@
    Write-Output $realProfileContent | Out-File -encoding ASCII "profile.ps1"
    Write-Host "`tScript Execution"
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  }
  finally {
    Pop-Location
  }
}

function Configure-Git() { 
  if ($gitFilePath -eq $null) {
    Write-Host "SKIP git configuration"
    return
  }

  Write-Host "Configuring Git"
  Write-Host "`tLocation: $gitFilePath"

  Write-Host "`tStandard Setup"
  $gitEditor = if ($vimFilePath -ne $null) { $vimFilePath } else { "notepad.exe" }
  Exec-Console $gitFilePath "config --global core.editor `"'$gitEditor'`""
  Exec-Console $gitFilePath "config --global user.name `"Jared Parsons`""
  Exec-Console $gitFilePath "config --global user.email `"jaredpparsons@gmail.com`""
  Exec-Console $gitFilePath "config --global fetch.prune true"
}

function Configure-Gpg() { 
  if ($gpgFilePath -eq $null) { 
    Write-Host "SKIP gpg configuration"
    return
  }

  Write-Host "Configuring GPG"
  if ($gitFilePath -ne $null) {
    Write-Host "`tGit"
    Exec-Console $gitFilePath "config --global gpg.program `"$gpgFilePath`""     
    Exec-Console $gitFilePath "config --global commit.gpgsign true"
    # Need to execute this manually
    # Get a new sub-key https://wiki.debian.org/Subkeys?action=show&redirect=subkeys
    # Exec-Console $gitFilePath "config --global user.signkey 06EDAA3E3C0AF8841559"  
  }

  Write-Host "`tgpg.conf"
  $sourceFilePath = Join-Path $dataDir "gpg.conf"
  $destFilePath = (Join-Path (Join-Path ${env:APPDATA} "gnupg") "gpg.conf")
  Copy-ConfigFile $sourceFilePath $destFilePath
}

function Configure-VSCode() { 
  Write-Host "Configuring VS Code"

  $settingsFilePath = Join-Path $dataDir "settings.json"
  $content = Get-Content -Raw $settingsFilePath
  $content = "// Actual settings file stored at: $settingsFilePath" + [Environment]::NewLine + $content
  $destFilePath = Join-Path ${env:APPDATA} "Code\User\settings.json"
  Copy-ConfigFile $settingsFilePath $destFilePath
}

# Used to add a startup.cmd file that does actions like map drives
function Configure-Startup() {
  Write-Host "Configuring Startup"
  $startupFilePath = Join-Path $generatedDir "startup.cmd"
  $shortcutFilePath = Join-Path ${env:USERPROFILE} "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startup.lnk"
  $codeDir = Join-Path ${env:USERPROFILE} "code"
  $toolsDir = Join-Path ${env:USERPROFILE} "OneDrive\Tools"

  $startupContent = @"
@echo off
REM This is a generated file. Do not edit. Instead put machine customizations into 
REM $PSCommandPath
subst p: $codeDir
subst t: $toolsDir
"@
  
  Write-Output $startupContent | Out-File -encoding ASCII $startupFilePath

  $objShell = New-Object -ComObject ("WScript.Shell")
  $objShortCut = $objShell.CreateShortcut($shortcutFilePath)
  $objShortCut.TargetPath = $startupFilePath
  $objShortCut.Save()
}

try {
  . (Join-Path $PSScriptRoot "PowerShell\Common-Utils.ps1")
  Push-Location $PSScriptRoot

  if ($badArgs -ne $null) {
    Write-Host "Unsupported argument $badArgs"
    Print-Usage
    exit 1
  }

  # Add the _vimrc file to the %HOME% path which just calls the real 
  # one I have in data\vim
  $repoDir = Split-Path -parent $PSScriptRoot
  $commonDataDir = Join-Path $repoDir "CommonData"
  $dataDir = Join-Path $PSScriptRoot "Data"
  $generatedDir = Join-Path $PSScriptRoot "Generated"
  Create-Directory $generatedDir

  $vimFilePath = Get-VimFilePath
  $gitFilePath = Get-GitFilePath
  $gpgfilePath = Get-GpgFilePath

  Configure-Startup
  Configure-Vim
  Configure-PowerShell
  Configure-Git
  Configure-Gpg
  Configure-VSCode

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
