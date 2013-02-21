
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

#==============================================================================
# Specialized M# prompt 
#==============================================================================
function prompt() 
{
    write-host -NoNewLine -ForegroundColor Red "Midori "
    if (${env:MIDORI_MSHARP_CHECK} -eq "true") {
        write-host -NoNewLine -ForegroundColor Red "Check "
    }

	write-host -NoNewLine -ForegroundColor Green $(get-location)

	foreach ($entry in (get-location -stack)) {
		write-host -NoNewLine -ForegroundColor Red '+';
	}
	write-host -NoNewLine -ForegroundColor Green '>'
	' '
}

function dd { cd (split-path -parent $env:MidRoot) }
function promiseBench { cd (join-path $env:MidRoot "Internal\Benchmarks\PromiseBench") }


