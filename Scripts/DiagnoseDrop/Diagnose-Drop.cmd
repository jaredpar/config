echo off

set SourcePath=%~dp0
if "%RazzleToolPath%" == "" (
    echo Must be run in a razzle window"
    exit
)

copy %SourcePath%\ddpowershell.exe.config "%RazzleToolPath%\x86\managed\v4.0"
%RazzleToolPath%\x86\managed\v4.0\ddpowershell %SourcePath%\Diagnose-Drop.ps1

