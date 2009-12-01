
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 

# Load all of the library functions
$libPath = join-path $scriptPath "LibraryCommon.ps1"
. $libPath

# First make sure that PowerShell script execution is enabled on this machine
if ( -not (Test-Admin) ) {
    Invoke-Admin powershell "-Command Set-ExecutionPolicy RemoteSigned"
} else {
    Invoke-Admin powershell "-Command Set-ExecutionPolicy RemoteSigned"
}

$isRedmond = $env:UserDomain -eq "Redmond"
if ( $isRedmond ) {
    # If at work ensure that we have the ISA firewall client installed.  If it's not
    # installed then Git can't be accessed to check out our configuration
    $fcPath = join-path $progPath "Microsoft Firewall Client 2004"
    if ( -not (test-path $fcPath) ) { 
        write-host "Installing ISA Firewall Client"
        $filePath = "\\products\public\products\Applications\Server\Firewall Client for ISA Server\ISACLIENT-KB929556-ENU.EXE"
        $s = [Diagnostics.Process]::Start($filePath)
    $s.WaitForExit()
}

# Copy all of the keys to the home directory
copy -re -fo (join-path $scritpPath ".ssh") $env:UserProfile

# Install Git if it's not already installed
$gitExe = join-path (Get-ProgramFiles32) "Git\bin\git.exe")
if ( -not (test-path $gitExe ) ) { 
    & (join-path $scriptPath "Git-Setup.exe")
    set-alias git $gitExe
}

pushd $env:UserProfile
git clone git@github.com:jaredpar/winconfig.git

$winconfigPath = resolve-path "winconfig" 
cd winconfig

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
