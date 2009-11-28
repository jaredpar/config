
set /P BUILD_NUMBER="Enter the drop number: "
set SRC=\\cpvsbuild\drops\dev10\vs_langs\raw\%BUILD_NUMBER%
set DEST=c:\symbols\%BUILD_NUMBER%
mkdir %DEST%

REM robocopy /r:2 /mir "%SRC%\binaries.x86chk"       "%DEST%\binaries.x86chk"     *.pdb
robocopy /r:2 /mir "%SRC%\binaries.x86ret"       "%DEST%\binaries.x86ret"     *.pdb
