#####
#
# Configure the Windows environment based on the script contents
#
####
[CmdletBinding(PositionalBinding=$false)]
param ([parameter(ValueFromRemainingArguments=$true)] $badArgs)

Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

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

# Configure both the vim and vsvim setup
function Configure-Vim() { 
    if ($vimFilePath -eq $null) {
        Write-Host "Skipping vim configuration"
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

        Create-Directory "WindowsPowerShell"
        cd WindowsPowerShell

        $oldProfile = "Microsoft.PowerShell_profile.ps1" 
        if (Test-Path $oldProfile ) {
            Remove-Item $oldProfile
        }

        $realProfileFilePath = Join-Path $PSScriptroot "PowerShell\Profile.ps1"
        Write-Output ". `"$realProfileFilePath`"" | Out-File -encoding ASCII "profile.ps1"
    }
    finally {
        Pop-Location
    }
}

function Configure-Git() { 
    if ($gitFilePath -eq $null) {
        Write-Host "Skipping git configuration"
        return
    }

    Write-Host "Configuring Git"
    Write-Host "`tLocation: $gitFilePath"

    Write-Host "`tStandard Setup"
    $gitEditor = if ($vimFilePath -ne $null) { $vimFilePath } else { "notepad.exe" }
    Exec-Console $gitFilePath "config --global core.editor `"'$gitEditor'`""
    Exec-Console $gitFilePath "config --global user.name `"Jared Parsons`""
    Exec-Console $gitFilePath "config --global user.email `"jaredpparsons@gmail.com`""

    # Setup signing policy.
    $gpgFilePath = "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
    if (Test-Path $gpgFilePath) {
        Write-Host "`tConfiguring GPG"
        Exec-Console $gitFilePath "config --global gpg.program `"$gpgFilePath`""     
        Exec-Console $gitFilePath "config --global commit.gpgsign true"
        # Exec-Console $gitFilePath "config --global user.signkey 06EDAA3E3C0AF8841559"
    }
    else { 
        Write-Host "Skipped configuring GPG as it's not found $gpgFilePath"
    }
}

function Configure-VSCode() { 
    Write-Host "Configuring VS Code"

    $settingsFilePath = Join-Path $dataDir "settings.json"
    $content = Get-Content -Raw $settingsFilePath
    $content = "// Actual settings file stored at: $settingsFilePath" + [Environment]::NewLine + $content
    $destFilePath = Join-Path ${env:APPDATA} "Code\User\settings.json"
    Create-Directory (Split-Path -parent $destFilePath)
    Write-Output $content | Out-File -encoding ASCII $destFilePath
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
    $vimFilePath = Get-VimFilePath
    $gitFilePath = Get-GitFilePath

    Configure-Vim
    Configure-PowerShell
    Configure-Git
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
