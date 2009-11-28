@echo off
REM Get the variables for the machine
call "%~dp0..\SetVars.cmd"

pushd %USERPROFILE%
if EXIST "My Documents" (
    cd "My Documents"
) else (
    if EXIST "Documents" (
        cd Documents
    ) else (
        mkdir Documents
        cd Documents
    )
)

if NOT EXIST WindowsPowerShell mkdir WindowsPowerShell
cd WindowsPowerShell
echo . "%winconfig_path%\PowerShell\Profile.ps1" > Microsoft.PowerShell_profile.ps1

popd
