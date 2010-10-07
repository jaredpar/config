
echo "Redirecting PowerShell Profile"

$docPath = $([Environment]::GetFolderPath("MyDocuments"))
pushd $docPath

if ( -not (test-path "WindowsPowerShell"))
{
    mkdir WindowsPowerShell
}
cd WindowsPowerShell

$oldProfile = "Microsoft.PowerShell_profile.ps1" 
if ( test-path $oldProfile )
{
    del $oldProfile
}

$profile = split-path -parent $PSScriptRoot
$profile = split-path -parent $profile
$profile = join-path $profile "Profile.ps1"

$cmd = ". `"" + $profile + "`""
echo $cmd > profile.ps1 

popd
