@echo off

REM Script used to initialize a new machine.  Gets PowerShell and Subversion
REM on the machine.  Also performs an initial checkout of the sources



pushd %~dp0
pushd ..
utils\envset /u WINCONFIG_PATH=%CD%

REM Since cmd.exe doesn't accept environment variable broadcasts, set 
REM the variable here before calling the configuration scripts
set WINCONFIG_PATH=%CD%

popd

goto CheckPath

set FOUND=""
:FindInPath
set FOUND=%~$PATH:1
goto :EOF

:CheckPath

REM Used to update the path.  We want to be careful here to make sure that
REM we don't keep updating the path with the same value so make sure
REM to check and see if our values are in the path

pushd %WINCONFIG_PATH%
call :FindInPath "envset.exe"
if /i "%FOUND%" == "%CD%\Utils\envset.exe" (
    echo Path already set
) else (
    %WINCONFIG_PATH%\Utils\envset /u PATH=\%PATH\%;"%CD%\Utils"
    PATH %CD%\Utils;%PATH%
)
popd

call ConfigureAll.cmd

popd
