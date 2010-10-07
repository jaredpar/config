
function Get-MidoriBuild() {
    param ( $branch = "framework",
            [switch]$built = $true )
    $sourcePath = join-path "e:\dd\midori\branches" $branch
    if ( $built ) {
        $sourcePath = join-path $sourcePath "Midori.obj\Windows\x64.Debug"
    }
    else {
        $sourcePath = join-path "e:\dd\midori\branches" $branch
        $sourcePath = join-path $sourcePath "Midori.obj\CIBTools"
    }
    $devPath = (join-path $env:userprofile "Midori")
    pushd (join-path $env:DepotRoot "midori\assemblies")
    tf edit *
    foreach ( $i in gci *) {
        copy (join-path $sourcePath $i.Name) .
        copy $i.FullName $devPath
    }
    popd
}

if ( test-path env:\DepotRoot ) {
    set-alias updatebin (join-path $env:DepotRoot "midori\build\scripts\updatebinaries.cmd")
}

new-psdrive -name suites -PSProvider FileSystem -root (join-path $env:DepotRoot "ddsuites\src\vs\safec\compiler")
new-psdrive -name msharp -PSProvider FileSystem -root (join-path $env:DepotRoot "csharp\LanguageAnalysis\Compiler")

