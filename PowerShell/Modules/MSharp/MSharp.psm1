
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
# Copy the M# build into the Midori branch 
#==============================================================================
function Publish-MsharpDrop() {
    param ( $branch = "framework",
            $midRoot = "e:\dd\midori",
            [switch]$noIde = $false )

    $target = join-path $midRoot "branches"
    $target = join-path $target $branch
    $target = join-path $target "Midori\Internal\Bin\Windows\clr"
    write-host "Target: $target"
    if ( -not (test-path env:\BinaryRoot ) ) {
        write-error "Must be run in a razzle window"
        return
    }

    # Check out all of the destination files
    pushd $target
    sd edit csc*
    sd edit chk\*
    sd edit 1033\cscui.dll
    popd

    # First publish the M# Retail compiler over 
    $source = join-path ${env:BinaryRoot} "x86ret\bin\i386"
    copy (join-path $source "csc.exe") $target
    copy (join-path $source "csc.pdb") $target
    copy (join-path $source "cscui.dll") (join-path $target "1033")

    # Next publish the M# check compiler
    $source = join-path ${env:BinaryRoot} "x86chk\bin\i386"
    $chkTarget = join-path $target "chk"
    copy (join-path $source "csc.exe") $chkTarget
    copy (join-path $source "csc.pdb") $chkTarget
    copy (join-path $source "cscui.dll") $chkTarget

    # Now deploy the IDE
    if (-not $noIde) {
        $target = join-path $midRoot "branches"
        $target = join-path $target $branch
        $target = join-path $target "Midori\Internal\Bin\Windows\MSharpIde"
        $script = join-path $env:DepotRoot "Midori\Build\Scripts\Install\MakeDrop.ps1"
        & $script $target
    }
}

#==============================================================================
# Publish a quick CHK drop for testing 
#==============================================================================
function Publish-TestDrop() {
    param ( $branch = "framework",
            $midRoot = "e:\dd\midori")

    $target = join-path $midRoot "branches"
    $target = join-path $target $branch
    $target = join-path $target "Midori\Internal\Bin\Windows\clr"
    write-host "Target: $target"
    if ( -not (test-path env:\BinaryRoot ) ) {
        write-error "Must be run in a razzle window"
        return
    }

    # Make sure we can copy over them
    sd edit (join-path $target "csc.exe")
    sd edit (join-path $target "csc.pdb")
    sd edit (join-path $target "1033\cscui.dll")

    # Publish the M# check compiler
    write-host "Source: $(${env:_NTBINROOT})"
    $source = join-path ${env:_NTBINROOT} "bin\i386"
    copy (join-path $source "csc.exe") $target
    copy (join-path $source "csc.pdb") $target
    copy (join-path $source "cscui.dll") (join-path $target "1033")
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
# Start the ddsenv window 
#==============================================================================


#==============================================================================
# Specialized razzle prompt 
#==============================================================================
function prompt() {
    write-host -NoNewLine -ForegroundColor Red "Razzle $env:_BuildType "
	write-host -NoNewLine -ForegroundColor Green $(get-location)
	foreach ( $entry in (get-location -stack))
	{
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

set-alias updatebin (join-path $env:DepotRoot "midori\build\scripts\updatebinaries.cmd") -scope Global
set-alias dd Set-DepotLocation -scope Global
set-alias msharp Set-MSharpLocation -scope Global
set-alias csharp Set-MSharpLocation -scope Global
set-alias lang Set-LangLocation -scope Global
set-alias compiler Set-CompilerLocation -scope Global
set-alias suites Set-SuitesLocation -scope Global
set-alias resources Invoke-ResourceBuild -scope Global

${env:SDEDITOR} = (join-path (Get-ProgramFiles32) "Vim\vim72\gvim.exe") + " --nofork"

