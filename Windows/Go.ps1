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
    $all = @("vim80", "vim74")
    foreach ($version in $all) { 
        $p = "C:\Program Files (x86)\Vim\$($version)\vim.exe"
        if (Test-Path $p) { 
            return $p
        }
    }

    return $null
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

    Configure-Vim
    Configure-PowerShell

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
