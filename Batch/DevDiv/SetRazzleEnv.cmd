
REM Default Variable Set
set VSPATH=D:\Program Files\Microsoft Visual Studio 8
set DEPOTROOT=%SDXROOT%

:NextArg

if /I "%1" == "VSPATH" set VSPATH=%2&shift&goto ArgOK
if /I "%1" == "DEPOTROOT" set DEPOTROOT=%2&shift&goto ArgOK

if "%1" == "" goto ArgDone

echo Unknown Argument: %1
goto Usage

:ArgOK
shift
goto NextArg

:ArgDone

REM Verify Arguments
if "%VSPATH%" == "" goto MissingValue
if "%DEPOTROOT%" == "" goto MissingValue

echo Running SetRazzleEnv

REM Add our directory to the path since we include a lot of the 
REM utilities used from a devdiv path
SET MYPATH=%~dp0
if "%MYPATH:~-1%" == "\" set MYPATH=%MYPATH:~0,-1%
set PATH=%path%;%MYPATH%

REM Also include the vb script commands
set PATH=%path%;%DEPOTROOT%\BranchDefinitions\VB03
set MYPATH=

REM Update the title and prompt
set _ArgTitle=
set _ArgNoTitle=true
title %_BuildType% %DepotRoot%
prompt Razzle %_BuildType% $P$G
goto :EOF

:MissingValue

echo !!! ERROR: Variable not set !!!
goto :EOF

:Usage

echo Setup Variables for the DevDiv environment
