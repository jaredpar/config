
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

$cmd = ". `"" + $(join-path $Jsh.ScriptPath "Profile.ps1") + "`""
echo $cmd > profile.ps1 

popd
