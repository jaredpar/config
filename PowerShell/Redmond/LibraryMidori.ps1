
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

set-alias sd \\ptt\Release\SD\Current\X86\sd.exe 

# Notepad.exe was removed from c:\windows and sd.exe still looks there.  Redirect
# it
$env:SDFORMEDITOR = join-path $env:WINDIR "System32\notepad.exe"

