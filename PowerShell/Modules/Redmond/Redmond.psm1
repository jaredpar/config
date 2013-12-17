

function Get-BranchPath() {
    param ( [string]$branch = $(throw "Pick a branch"))

    $path = $null;
    foreach ($root in @('c:\dd', 'd:\dd', 'e:\dd')) {
        if (-not (test-path $root)) {
            continue;
        }

        $branchPath = join-path $root 'Midori\branches'
        $branchPath = join-path $branchPath $branch
        if (test-path $branchPath) {
            $path = $branchPath
            break;
        }

        $branchPath = join-path $root $branch
        if (test-path $branchPath) {
            $path = $branchPath
            break;
        }
    }

    if ($path -eq $null) {
        write-error "Branch doesn't exist: $branch"
    }

    return $path
}	

# Method to startup a Midori environment
function Set-Midori() {
    param ( [string]$branch = $(throw "Pick a branch"))

    $path = Get-BranchPath $branch

    if ($path -eq $null) {
        write-error "Branch doesn't exist: $branch"
        return
    }

    $other = Join-Path $path "Other\devdiv\readme.txt"
    if (-not (Test-Path $other)) {
        $choices = @('e:\dd\kernel', 'e:\dd\tools', 'e:\dd\framework')
        foreach ($choice in $choices) { 
            $choice = Join-Path $choice "Other"
            if (Test-Path (Join-Path $choice "DevDiv\readme.txt")) {
                ${env:OTHERROOT} = $choice;
                break;
            }
        }
    }

    cd $path
    cd Midori
    . .\setenv.ps1 /x64 /iso /nocops
    import-module Midori -Global
    . set-env 
    $Host.UI.RawUI.WindowTitle = "Midori"
}	

# Disable strong name verification on the machine
function Disable-StrongName() {
    $path = join-path (Get-ProgramFiles32) "Microsoft SDKS\Windows\v7.0A\Bin"
    $sn = join-path $path "sn.exe"
    $sn64 = join-path $path "x64\sn.exe" 

    if ( -not (Test-Admin) ) {
        write-error "Must be an admininstrator to run this"
        return
    }

    & $sn -Vr *
    & $sn64 -Vr *
}

# Search for types
function Select-StringRecurseType() {
    param ( [string]$name = $(throw "Need text to search for"),
            [string[]]$include = "*",
            [switch]$all= $false,
            [switch]$caseSensitive=$false)

    $text = "(class|struct|interface)\s*\b" + $name + "\b"
    Select-StringRecurse $text $include $all $caseSensitive
}   

set-alias odd \\midweb\scratch\jaredpar\tools\odd\odd.exe -scope Global
set-alias ssrt Select-StringRecurseType -Scope global

