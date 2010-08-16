
# Remove the previous LUA monitor program
echo "Removing LuaProcessMonitor"
$proc = gps LuaProcessMonitor -ErrorAction SilentlyContinue
if ( $proc -ne $null ) {
    kill $proc
}

rp hkcu:\Software\Microsoft\Windows\CurrentVersion\Run LuaProcessMonitor -ErrorAction SilentlyContinue
