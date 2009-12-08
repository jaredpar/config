
$script = $MyInvocation.MyCommand.Definition 
$scriptPath = split-path -parent $script 
. (join-path $scriptPath "LibraryCommon.ps1")

$assemblies = @(
 "Microsoft.VisualBasic.Editor",
 "Microsoft.VisualBasic.LanguageService",
 "Microsoft.VisualStudio.VisualBasic.LanguageService",
 "Microsoft.VisualStudio.VisualBasic.QuickSearch")


if ( -not (Test-Admin)) {
    write-host "Launching as an administrator"
    Invoke-ScriptAdmin $script "-ExecutionPolicy RemoteSigned" -waitForExit
    return
}

if ( Test-Path env:\DepotRoot ) {
    write-host "Error: Do not run from a razzle environment" 
    return
}

$backupPath = "UngacBackup-" + ([GUID]::NewGuid().ToString())
$backupPath = join-path $env:UserProfile $backupPath 
write-host "Backup directory: $backupPath"
mkdir $backupPath | out-null

write-host "Exporting registry entries that must be changed"
$regPath = "HKLM:\Software\Classes\Installer\Assemblies\Global"
& reg export $($regPath.Replace(":","")) $(join-path $backupPath global.reg)

write-host "Removing registry entries"
pushd $regPath
$prop = gp .
foreach ($assembly in $assemblies ) {
    foreach ( $entry in ($prop.PSObject.Properties | ?{ $_.Name.StartsWith($assembly) }) ) {
        write-host "`tRemoving: $($entry.Name)"
        remove-itemproperty -path $regPath -name $entry.Name
    }
}
popd

write-host "Ungac'ing the DLL's"
$gacutil = Get-ProgramFiles32
$gacutil = join-path $gacutil "Microsoft SDKs\Windows\v7.0A\bin\NETFX 4.0 Tools\gacutil.exe"
foreach ( $assembly in $assemblies ) {
    & $gacutil /u $assembly /nologo
}

