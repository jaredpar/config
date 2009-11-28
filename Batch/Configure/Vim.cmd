@echo off

setlocal
call "%~dp0..\SetVars.cmd"

set VIM_PATH=%DATA_PATH%\vim
envset /u HOME="%VIM_PATH%"

endlocal
