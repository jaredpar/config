
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 
$setupDir = join-path ([IO.Path]::GetPathRoot($scriptPath)) "MachineSetup"
$winconfigPath = join-path $env:UserProfile "winconfig" 

# Load all of the library functions
$libPath = join-path $scriptPath "LibraryCommon.ps1"
. $libPath

$progPath = Get-ProgramFiles32

# Make sure that PowerShell script execution is enabled on this machine
function EnableScriptExecution() {
    if ( (Get-ExecutionPolicy) -ne "RemoteSigned" ) {
        if ( -not (Test-Admin) ) {
            Invoke-Admin powershell "-Command Set-ExecutionPolicy RemoteSigned"
        } else {
            Invoke-Admin powershell "-Command Set-ExecutionPolicy RemoteSigned"
        }
    }
}

function ConfigureWorkMachine() {
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
    }
}

# Copy all of the keys to the home directory and ensure that %HOME% is 
# not pointed to previous places my setup scripts pointed to
function EnableSsh() {
    copy -re -fo (join-path $setupDir ".ssh") $env:UserProfile
    if ( test-path env:\home ) { rm env:\home }
}

function EnableGit() {
    # Install Git if it's not already installed
    $gitExe = join-path $progPath "Git\bin\git.exe"
    if ( -not (test-path $gitExe ) ) { 
        $setupPath = join-path $setupDir "Git-Setup.exe"
        $s = [Diagnostics.Process]::Start($setupPath) 
        $s.WaitForExit() 
        set-alias git $gitExe
    }
}

function CheckoutWinConfig() {
    pushd $env:UserProfile
    
    # Remove any old winconfig directory
    if ( test-path "winconfig" ) {
        $dest = "winconfig_" + [Guid]::NewGuid().ToString()
        move "winconfig" $dest
        gps LuaProcessMonitor  | kill -ErrorAction SilentlyContinue
    }
    
    git clone git@github.com:jaredpar/winconfig.git
    popd
}

# Nuke the favorites folder.  The default install adds a lot of favorites
# that you don't ever want to use anyways so go ahead and delete them. The
# Favorites configuration will add everything in that you actually need
function RemoveFavorites() {
    pushd $([Environment]::GetFolderPath("Favorites"))
    rm -force -recurse *
    popd
}

function RunConfiguration() {
    pushd $winconfigPath
    # Run the normal configuration scripts.  Load the profile script
    # so the environment is properly set
    . $(join-path $winconfigPath "PowerShell\Profile.ps1")

    # Run the configuration script
    & (join-path $winconfigPath "PowerShell\ConfigureAll.ps1")

    popd
}

# Enable various tools such as reflector
function EnableTools() {
    $reflector = join-path $setupDir "reflector.exe"
    copy -fo $reflector (join-path $env:UserProfile "Desktop")
}

EnableScriptExecution
ConfigureWorkMachine
EnableSsh
EnableGit
CheckoutWinConfig
EnableTools
RemoveFavorites
RunConfiguration

