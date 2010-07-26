
function Update-MidoriBin() {
    param ( $branch = "framework") 
    $sourcePath = join-path "e:\dd\midori\branches" $branch
    $sourcePath = join-path $sourcePath "Midori.obj\CIBTools"
    $devPath = (join-path $env:userprofile "Midori")
    pushd (join-path $env:DepotRoot "midori\assemblies")
    foreach ( $i in gci *) {
        copy (join-path $sourcePath $i.Name) .
        copy $i.FullName $devPath
    }
    popd
}

set-alias sd \\ptt\Release\SD\Current\X86\sd.exe 

