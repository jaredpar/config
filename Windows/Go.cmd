@echo off
set SOURCE=%~dp0

REM Used the -ExecutionPolicy switch because it's likely that
REM execution of scripts is not enabled yet
pwsh -NoProfile -ExecutionPolicy RemoteSigned %SOURCE%\Go.ps1 %*
