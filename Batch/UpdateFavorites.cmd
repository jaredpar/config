@echo off
call "%~dp0SetVars.cmd"

goto :Start
:AddFile

echo Adding %1
svn add %1
goto :EOF

:DeleteFile
echo Deleting %1
svn delete %1
goto :EOF

:Start
set TMP_FILE=%TMP%\fav.txt
pushd %DATA_PATH%\Favorites

REM Create the status file
if EXIST "%TMP_FILE%" del "%TMP_FILE%" 
svn status . > "%TMP_FILE%"

REM Make sure an update is even necessary
set LINECOUNT=0
for /F "usebackq tokens=4,5" %%i in (`dir %TMP_FILE%`) do (
    if "%%j" == "fav.txt" set LINECOUNT=%%i
)

if %LINECOUNT% == 0 (
    echo "No Changes Found"
    goto :Done
)
        
for /F "tokens=1,*" %%i in (%TMP_FILE%) do (
    if "%%i" == "?" call :AddFile "%%j"
    if "%%i" == "!" call :DeleteFile "%%j"
)

svn commit -m "Updating Favorites"

:Done
popd
