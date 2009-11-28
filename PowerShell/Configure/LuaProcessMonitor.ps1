
if ( $Jsh.IsTestMachine ) {
    return
}

# Set LUA process monitor to run when we login
echo "Making LuaProcessMonitor start on login"
$luaExe = join-path $Jsh.UtilsRawPath "LuaProcessMonitor.exe"
sp hkcu:\Software\Microsoft\Windows\CurrentVersion\Run LuaProcessMonitor $luaExe

$found = @( $(gps LuaProcessMonitor -ea SilentlyContinue))
if ( $found.Length -eq 0 )
{
    ii $luaExe
}
