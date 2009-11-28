$initPath = split-path -parent $MyInvocation.MyCommand.Definition 

. (join-path $initPath "LibraryCommon.ps1") # load the common functions
$progPath = Get-ProgramFiles32

# First step is to ensure that we have the ISA firewall client installed.  If it's not
# installed then Subversion can't be accessed to check out our configuration
$fcPath = join-path $progPath "Microsoft Firewall Client 2004"
if ( -not (test-path $fcPath) ) { 
    write-host "Installing ISA Firewall Client"
    $filePath = "\\products\public\products\Applications\Server\Firewall Client for ISA Server\ISACLIENT-KB929556-ENU.EXE"
    $s = [Diagnostics.Process]::Start($filePath)
    $s.WaitForExit()
}

# Next step is to check and see if Subversion is installed.
$svnPath = join-path $progPath "Subversion"
if ( -not (test-path $svnPath) ) { 
    write-host "Installing Subversion"
    $filePath="\\vbqafiles\public\jaredpar\Setup-Subversion-1.5.2.en-us.msi"
    $s = [Diagnostics.Process]::Start($filePath)
    $s.WaitForExit()
}

cd $env:UserProfile
if ( -not (test-path ".\winconfig\Powershell\Profile.ps1")) {
    write-host "Checking out configuration"
    $svn = join-path $svnPath "bin\svn.exe" 
    & $svn co https://wush.net/svn/jaredp110680/winconfig --username jaredp110680
}

# By default make this a test machine
$target = join-path $env:UserProfile "winconfig\PowerShell\LocalComputer"
mkdir $target
$target = join-path $target "Profile.ps1"
copy --force (join-path $initPath "ComputerProfile.ps1") $target

& (join-path $env:UserProfile "winconfig\Powershell\InitMachine.ps1")
