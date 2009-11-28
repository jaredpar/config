@echo off

REM This command sets up all of the variables for the
REM current machine.  If no machine specific one exists
REM yet then it will be created with default values 

set THIS_PATH=%~dp0
if "%THIS_PATH:~-1%" == "\" set THIS_PATH=%THIS_PATH:~0,-1%

REM Begin Global Variables ---------------------------------------------------

REM Data and utils path are typically one directory level above the one
REM containing this script.  Cd into the dirs and use the the %CD% to
REM avoid having ..\ in the path
pushd %THIS_PATH%
cd ..
set ENLISTMENT_PATH=%CD%
set DATA_PATH=%CD%\Data
set UTILS_PATH=%CD%\Utils
set IS_DEVDIV=0
popd

REM If this is a DevDiv machine call the specific startup scripts
if "%USERDOMAIN%" == "REDMOND" (
    set IS_DEVDIV=1
    call "%THIS_PATH%\DevDiv\SetVars.cmd"
)

REM End Global Variables ---------------------------------------------------

set COMP_FILE=%THIS_PATH%\Machines\%COMPUTERNAME%.cmd

if NOT EXIST "%COMP_FILE%" (
	echo "Generating computer variable file"
	copy "%THIS_PATH%\_CompDefault.cmd" "%COMP_FILE%"
) ELSE (
	call "%COMP_FILE%"
)

REM Delete local variables
set COMP_FILE=
