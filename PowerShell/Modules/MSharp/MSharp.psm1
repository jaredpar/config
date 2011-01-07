
#==============================================================================
# Copy the Midori build into the M# branch and personal development folder 
#==============================================================================
function Copy-MidoriBuild() {
    param ( $branch = "framework",
            $midRoot = "e:\dd\midori" )
    $source = join-path $midRoot "branches"
    $source = join-path $source $branch
    $source = join-path $source "Midori.obj\CIBTools"

    $devPath = (join-path $env:userprofile "Midori")
    pushd (join-path $env:DepotRoot "midori\assemblies")
    tf edit *
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
            [switch]$allCheck = $false)
    $target = join-path $midRoot "branches"
    $target = join-path $target $branch
    $target = join-path $target "other\Ext-Tools\clr\v4.0.msharp"
    write-host "Target: $target"
    if ( -not (test-path env:\BinaryRoot ) ) {
        write-error "Must be run in a razzle window"
        return
    }

    $retTarget = join-path $target "msharp.x86ret"
    $chkTarget = join-path $target "msharp.x86chk" 
    $retSource = join-path ${env:BinaryRoot} "x86ret\bin\i386"
    $chkSource = join-path ${env:BinaryRoot} "x86chk\bin\i386"
    if ( $allCheck ) { 
        $retSource = $chkSource
    }

    if ( -not (test-path $retTarget) ) {
        mkdir $retTarget;
    }

    if ( -not (test-path $chkTarget) ) {
        mkdir $chkTarget;
    }
    copy (join-path $retSource "csc.exe") $retTarget
    copy (join-path $retSource "csc.pdb") $retTarget
    copy (join-path $retSource "cscui.dll") (join-path $retTarget "1033")
    copy (join-path $retSource "csc.exe") $target
    copy (join-path $retSource "csc.pdb") $target
    copy (join-path $retSource "cscui.dll") (join-path $target "1033")
    copy (join-path $chkSource "csc.exe") $chkTarget
    copy (join-path $chkSource "csc.pdb") $chkTarget
    copy (join-path $chkSource "cscui.dll") (join-path $chkTarget "1033")
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


