@echo off

setlocal
call "%~dp0..\SetVars.cmd"

setreg HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\LuaProcessMoniter SZ "%UTILS_PATH%\LuaProcessMonitor.exe"

REM Kill any running instances of LuaProcessMoniter and start up a new one.  
REM kill fails to stop a process we don't care
echo Killing existing instances of LuaProcessMonitor (errors OK)
kill -f LuaProcessMonitor.exe
start "" "%UTILS_PATH%\LuaProcessMonitor.exe"

endlocal
