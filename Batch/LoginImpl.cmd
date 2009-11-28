
REM This is the actual login script.  It will allow for machine specific actions by
REM calling or creating the machine script.  

pushd "%~dp0"
call SetVars.cmd

echo General Login Script

REM Call or create the machine login script
set MACH_SCRIPT=Machines\%COMPUTERNAME%_Login.cmd
if NOT EXIST %MACH_SCRIPT% (
    echo    Creating Login Script for %COMPUTERNAME%
    echo REM %COMPUTERNAME% Login script > %MACH_SCRIPT%
    echo REM SetVars has already been called >> %MACH_SCRIPT%
)

echo    Calling %COMPUTERNAME% Login Script
call %MACH_SCRIPT%

REM Run DevDiv specific configuration
if %IS_DEVDIV% == 1 (
    echo    Calling DevDiv Login Script
    call "%ENLISTMENT_PATH%\Batch\DevDiv\LoginImpl.cmd"
)

popd
