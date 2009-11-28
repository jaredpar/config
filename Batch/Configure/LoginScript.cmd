@echo off

REM Get the variables for the machine
call "%~dp0..\SetVars.cmd"

REM Run the login script when logging into the computer
setreg HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\LoginScript SZ "%ENLISTMENT_PATH%\Batch\Login.cmd"

