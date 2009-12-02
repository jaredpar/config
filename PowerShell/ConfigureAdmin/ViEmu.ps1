
$script:product = get-wmiobject Win32_Product -ea SilentlyContinue |
    ? { $_.Name -like "ViEmu*" }

function script:Has-Vs() {
    $versions = "8","9.0"
    foreach ($v in $versions) {
        $p = join-path (Get-ProgramFiles32) "Microsoft Visual Studio $v"
        $p = join-path $p "Common7\ide\devenv.exe"
        if ( test-path $p ) {
            return $true;
        }
    }

    return $false
}

$check = $args[0]
if ( $check -eq "check" ) {
    if ( -not (Has-VS) ) {
        return $false
    }

    # Don't install ViEmu on any test machines
    if ( $Jsh.IsTestMachine ) {
        return $false
    }

    if ( $product -eq $null -or (-not ($product.Version -like "2.2.8*")) ) {
        return $true
    }

    return $false
}

# Make sure DevEnv is not running otherwise this will cause some problems
$list = @(gps *devenv -ea silentlycontinue)
if ( $list.Count -ne 0 ) {
    write-host "ERROR!!! Please shut down all visual studio instances before running"
    return
}

$filePath = join-path $env:temp "ViEmuVS.msi"
if ( test-path $filePath ) {
    del --force $filePath
}

write-host "Downloading setup file"
wget http://www.viemu.com/ViEmuVS.msi $filePath

if ( $product -ne $null ) {
    write-host "Removing old version"
    $product.Uninstall()
}

write-host "Running setup"
$s = [Diagnostics.Process]::Start($filePath)
$s.WaitForExit()

