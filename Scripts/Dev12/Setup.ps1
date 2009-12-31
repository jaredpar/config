$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 
. $(join-path $scriptPath "LibraryCommon.ps1")


# Set the alias for tf.exe so it can be used from the command line
write-host "Setting tf.exe alias"
$path = Get-ProgramFiles32
$path = join-path $path "Microsoft Visual Studio 10.0\Common7\IDE\tf.exe"
set-alias tf $path
