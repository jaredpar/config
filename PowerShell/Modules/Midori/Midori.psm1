
function Update-MidoriBin() {
    param ( $branch = "framework",
            [switch]$built = $true )
    $sourcePath = join-path "e:\dd\midori\branches" $branch
    if ( $built ) {
        $sourcePath = join-path $sourcePath "Midori.obj\Windows\x86.Debug"
    }
    else {
        $sourcePath = join-path "e:\dd\midori\branches" $branch
        $sourcePath = join-path $sourcePath "Midori.obj\CIBTools"
    }
    $devPath = (join-path $env:userprofile "Midori")
    pushd (join-path $env:DepotRoot "midori\assemblies")
    foreach ( $i in gci *) {
        copy (join-path $sourcePath $i.Name) .
        copy $i.FullName $devPath
    }
    popd
}

function Update-Alias() { 
    set-alias -Scope "Global" kdbridge (join-path $env:DevToolsDir "kdbridge.exe") 
}

function Update-MkPromise() {
    pushd 

    cd (join-path $env:MidRoot "Tools\Applications\MkPromise")
    msb /w /notools
    cd (join-path $env:MidRoot "Internal\Bin\CIB")
    sd edit MkPromise*

    $source = join-path $env:MidRoot "..\Midori.obj\Windows\x86.Debug"
    copy (join-path $source "MkPromise.exe") .
    copy (join-path $source "MkPromise.pdb") .

    popd
}

function Set-Env() {
    param ( $distro = 'tiny' )

    pushd $env:MidRoot
    . .\setenv.ps1 /distro $distro /x64 /noselfhost /nocops /iso 
    popd 
}

function jb { 
    param ( [string]$arg1 = "",
            [string]$arg2 = "")

    $log = join-path $env:MidRoot "log.txt"
    msb /notools /log:$log $arg1 $arg1
}

function fsb {
    param ( [string]$arg1 = "",
            [string]$arg2 = "")

    $log = join-path $env:MidRoot "log.txt"
    msb /notools /nodepexe /log:$log $arg1 $arg1
}

function bmkpromise {
    pushd $env:MidRoot
    msb /w /notools Tools\Applications\MkPromise\MkPromise.csproj

    $source = join-path $env:MidRoot "..\Midori.obj\Windows\AnyCPU.Debug\MkPromise.exe"
    $dest =join-path $env:MidRoot "Internal\Bin\CIB\MkPromise.exe"
    sd edit $dest
    copy $source $dest
}

function pack {
    param ( [string]$name = $(throw "Need a pack name")) 

    jjpack pack (join-path "\\midweb\scratch\jaredpar\packs\" $name)
}

function dd { cd (split-path -parent $env:MidRoot) }
function midori { cd $env:MidRoot }
function foundation { cd (join-path $env:MidRoot "System\Core\Libraries\Platform-Foundation") }
function lib { cd (join-path $env:MidRoot "System\Core\Libraries") }
function promises { cd (join-path $env:MidRoot "System\Core\Libraries\Platform-Promises") }
function corlib { cd (join-path $env:MidRoot "System\Runtime\Corlib") }
function promiseBench { cd (join-path $env:MidRoot "Internal\Benchmarks\PromiseBench") }

set-alias sd $(resolve-path (join-path $env:MidRoot "Internal\Bin\Windows\sd.exe")) 

# Setup the SD editing functions
$env:SDEDITOR = (join-path (Get-ProgramFiles32) "Vim\vim72\gvim.exe") + " --nofork"
$env:SDFORMEDITOR = (join-path (Get-ProgramFiles32) "Vim\vim72\gvim.exe") + " --nofork"

