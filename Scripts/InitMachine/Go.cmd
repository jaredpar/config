@echo off
set SOURCE=%~dp0
powershell -ExecutionPolicy RemoteSigned %SOURCE%\GoHelper.ps1

REM set TARGET=%TMP%\Init
REM set PS=%WINDIR%\system32\WindowsPowershell\v1.0\powershell.exe 
REM mkdir %TMP%\Init
REM copy %SOURCE%\* %TARGET%

REM echo Source: %SOURCE%
REM echo Target: %TARGET%

REM call %TARGET%\Enable-PowerShell.cmd

REM %PS% -command "set-executionpolicy remotesigned"
REM %PS% %TARGET%\Redmond.ps1
