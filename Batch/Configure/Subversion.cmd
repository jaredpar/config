@echo off

setlocal
call "%~dp0..\SetVars.cmd"

set SVN_PATH=%APPDATA%\Subversion
if NOT EXIST "%SVN_PATH%" (
    mkdir "%SVN_PATH%"
)

copy /y "%DATA_PATH%\SubversionConfig.txt" "%SVN_PATH%\config"

endlocal
