
#==============================================================================
# Copy the Midori build into the M# branch and personal development folder 
#==============================================================================
function Copy-MidoriBuild() {
    param ( $branch = "framework",
            $midRoot = "e:\dd\midori" )

    if (-not (test-path env:\DepotRoot)) {
        throw "Must be run under a razzle window";
    }

    $source = join-path $midRoot "branches"
    $source = join-path $source $branch
    $source = join-path $source "Midori.obj\BuildTools"

    $devPath = (join-path $env:userprofile "Midori")
    pushd (join-path $env:DepotRoot "midori\assemblies")
    sd edit *
    foreach ( $i in gci *.dll,*.pdb) {
        copy (join-path $source $i.Name) .
        copy $i.FullName $devPath -force
    }
    popd
}

#==============================================================================
# Build the resources DLL 
#==============================================================================
function Invoke-ResourceBuild()
{
    pushd (join-path $env:DepotRoot "csharp\inc")
    build
    cd (join-path $env:DepotRoot "csharp\LanguageAnalysis\Compiler\Resources")
    build
    popd
}

#==============================================================================
# Build the command line compiler
#==============================================================================
function Invoke-CompilerBuild()
{
    Invoke-ResourceBuild

    pushd (join-path $env:DepotRoot "csharp\idl")
    build
    cd (join-path $env:DepotRoot "csharp\shared")
    build
    cd (join-path $env:DepotRoot "csharp\LanguageAnalysis\LIB") 
    build 
    cd (join-path $env:DepotRoot "csharp\LanguageAnalysis\Compiler\LIB") 
    build 
    cd (join-path $env:DepotRoot "csharp\LanguageAnalysis\Compiler\EXE\CSC") 
    build 
    popd
}

function Set-Env() 
{
    param ( [switch]$live=$false,
            [switch]$chk=$false )

    $setenv = Join-Path ${env:MidRoot} "setenv.ps1"
    if ($live -and $chk) {
        . $setenv /msharpPrebuilt=live /msharpCheck
    } elseif ($live) {
        . $setenv /msharpPrebuilt=live /nomsharpCheck
    } elseif ($chk) { 
        . $setenv /msharpPrebuilt=default /msharpCheck
    } else { 
        . $setenv /msharpPrebuilt=default /nomsharpCheck
        write-host "Nothing"
    }
}

#==============================================================================
# Specialized razzle prompt 
#==============================================================================
function prompt() {
    write-host -NoNewLine -ForegroundColor Red "M# "
    if (${env:MSHARP_PREBUILT_ARG} -eq "live") {
        write-host -NoNewLine -ForegroundColor Red "Live "
    }

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

function Set-MSharpLocation() { cd (join-path $env:DepotRoot "csharp") }
function Set-LangLocation() { cd (join-path $env:DepotRoot "csharp\LanguageAnalysis") }
function Set-CompilerLocation() { cd (join-path $env:DepotRoot "csharp\LanguageAnalysis\Compiler") }
function Set-SuitesLocation() { cd (join-path $env:DepotRoot "ddsuites\src\vs\safec\compiler\midori") }
function Set-DepotLocation() { cd $env:DepotRoot }

set-alias dd Set-DepotLocation -scope Global
set-alias msharp Set-MSharpLocation -scope Global
set-alias csharp Set-MSharpLocation -scope Global
set-alias lang Set-LangLocation -scope Global
set-alias compiler Set-CompilerLocation -scope Global
set-alias suites Set-SuitesLocation -scope Global
set-alias resources Invoke-ResourceBuild -scope Global
set-alias compiler Invoke-CompilerBuild -scope Global

${env:DepotRoot} = Resolve-Path (Join-Path ${env:MidRoot} "..\MSharp")
${env:SDEDITOR} = (join-path (Get-ProgramFiles32) "Vim\vim72\gvim.exe") + " --nofork"

