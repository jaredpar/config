@echo off
set SOURCE=%~dp0
set TARGET=%TMP%\Init
set PS=%WINDIR%\system32\WindowsPowershell\v1.0\powershell.exe 
mkdir %TMP%\Init
copy %SOURCE%\* %TARGET%

echo Source: %SOURCE%
echo Target: %TARGET%

call %TARGET%\Enable-PowerShell.cmd

%PS% -command "set-executionpolicy remotesigned"
%PS% %TARGET%\Redmond.ps1
