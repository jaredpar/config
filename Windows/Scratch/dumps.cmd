@echo off
REM Used the -ExecutionPolicy switch because it's likely that
REM execution of scripts is not enabled yet
powershell -NoProfile -ExecutionPolicy RemoteSigned %~dp0\dumps.ps1 %*