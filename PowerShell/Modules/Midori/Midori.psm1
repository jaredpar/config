
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

function Set-MidoriLocation() { cd $env:MidRoot }
function Set-DepotLocation() { cd (split-path -parent $env:MidRoot) }
function Set-PlatformFoundationLocation() { cd (join-path $env:MidRoot "System\Core\Libraries\Platform-Foundation") }
function Set-CorlibLocation() { cd (join-path $env:MidRoot "System\Runtime\Corlib") }
function Set-LibraryLocation() { cd (join-path $env:MidRoot "System\Core\Libraries") }

set-alias dd Set-DepotLocation -scope Global
set-alias midori Set-MidoriLocation -scope Global
set-alias platform Set-PlatformFoundationLocation -scope Global
set-alias corlib Set-CorlibLocation -scope Global
set-alias lib Set-LibraryLocation -scope Global
set-alias sd $(resolve-path (join-path $env:MidRoot "Internal\Bin\Windows\sd.exe")) 

# Notepad.exe was removed from c:\windows and sd.exe still looks there.  Redirect
# it
$env:SDFORMEDITOR = join-path $env:WINDIR "System32\notepad.exe"

