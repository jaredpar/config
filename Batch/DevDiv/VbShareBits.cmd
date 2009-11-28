@echo off

setlocal

set TARGET=%~1
if "%TARGET%" == "" goto Usage
if not exist "%TARGET%" goto Usage

pushd %_NTPOSTBLD%\bin\i386
copy /y vbc.exe %TARGET%
copy /y vbc7ui.dll %TARGET%
popd

goto :EOF

:Usage

echo VbShareBits path
goto :EOF

endlocal
