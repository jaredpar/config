@echo off

REM This script is called at login.  Mainly it sync's the current enlistment
REM and calls the actual login script (LoginImpl.cmd)

setlocal

REM Get to the root of the enlistment.
call "%~dp0SetVars.cmd"
pushd "%ENLISTMENT_PATH%"

REM Update the enlistment
svn update .

REM Call the actual login script
call Batch\LoginImpl.cmd
popd
endlocal
