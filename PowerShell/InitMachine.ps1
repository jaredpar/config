
$winconfigPath = split-path -parent $MyInvocation.MyCommand.Definition 
$winconfigPath = split-path -parent $winconfigPath

pushd $winconfigPath 

# Nuke the favorites folder.  The default install adds a lot of favorites
# that you don't ever want to use anyways so go ahead and delete them. The
# Favorites configuration will add everything in that you actually need
pushd $([Environment]::GetFolderPath("Favorites"))
rm -force -recurse *
popd

# Run the normal configuration scripts.  Load the profile script
# so the environment is properly set
. $(join-path $winconfigPath "PowerShell\Profile.ps1")

# Run the configuration script
& (join-path $winconfigPath "PowerShell\ConfigureAll.ps1")

popd

