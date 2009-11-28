@echo off

setlocal
call "%~dp0..\SetVars.cmd"

REM Add a path for all of my visual studio settings files
for %%i in ("%DATA_PATH%\VisualStudio\*.vssettings") do (
    regmod -c HKCU Software\Microsoft\VisualStudio\8.0\Profile\BrowseFiles "%%i" DWORD 1
)

REM Setup Rascal as well
for %%i in ("%DATA_PATH%\VisualStudio\*.vssettings") do (
    regmod -c HKCU Software\Microsoft\Rascal\8.0\Profile\BrowseFiles "%%i" DWORD 1
)
