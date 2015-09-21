@setlocal

:: 
:: Ensure-PowerShell.cmd
:: 
:: Ensure that PowerShell is installed on any machine

if /I (%1) == (-WhatIf) set WhatIf=true

::
:: check if PowerShell is already installed
::
for %%I in (powershell.exe) do if NOT (%%~$PATH:I) == () (
   echo PowerShell already installed to %%~$PATH:I
   exit /b 0
)

set PowerShell_InstallRoot=\\products\public\products\Applications\User\Windows PowerShell

::
:: Extract the version number of the local Windows system.
::
for /f "tokens=4,5 delims=.]XP " %%i in ('ver') do set VER=%%i.%%j
for /f "tokens=4,5,6 delims=.]XP " %%i in ('ver') do set FULLVER=%%i.%%j.%%k

echo Parsed VER=%VER% and FULLVER=%FULLVER%

if "%VER%" == "5.1" (
   
   if NOT "%PROCESSOR_ARCHITECTURE%" == "x86" (
      echo This install script only works for x86 Windows XP and not %PROCESSOR_ARCHITECTURE%
      exit /b 1
   )
   
   echo selecting PowerShell installer for Windows XP ^(X86^)
   set Installer="%PowerShell_InstallRoot%\XP\x86\WindowsXP-KB926139-x86-ENU.exe" /passive

) else if "%VER%" == "5.2" (

   if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
   
      echo selecting PowerShell installer for Windows Server 2003 ^(X64^)
      set Installer="%PowerShell_InstallRoot%\W2k3\ENU\x64\WindowsServer2003.WindowsXP-KB926139-x64-ENU.exe" /passive
      
   ) else if "%PROCESSOR_ARCHITECTURE%" == "x86" (
   
      echo selecting PowerShell installer for Windows Server 2003 ^(X86^)
      set Installer="%PowerShell_InstallRoot%\W2k3\ENU\x86\WindowsServer2003-KB926139-x86-ENU.exe" /passive
   
   ) else (
   
      echo This install script only works for x86 or x64 Windows Server 2003 and not %PROCESSOR_ARCHITECTURE%
      exit /b 1
   
   )

) else if "%VER%" == "6.0" (

   if "%FULLVER%" == "6.0.6000" (
   
       if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
       
          echo selecting PowerShell installer for Windows Vista ^(X64^)
          set Installer="%PowerShell_InstallRoot%\VistaRTM\X86fre\Windows6.0-KB928439-x64.msu" /quiet
       
       ) else if "%PROCESSOR_ARCHITECTURE%" == "x86" (
       
          echo selecting PowerShell installer for Windows Vista ^(X86^)
          set Installer="%PowerShell_InstallRoot%\VistaRTM\X86fre\Windows6.0-KB928439-x86.msu" /quiet
       
       ) else (
       
         echo This install script only works for x86 or x64 Windows Vista and not %PROCESSOR_ARCHITECTURE%
         exit /b 1
         
       )
       
   ) else (
   
       echo This install script only works for Vista RTM, not %FULLVER%.
       exit /b 1
       
   )

) else (

   echo Could not understand version string of %VER%.
   echo.
   echo If you're on Longhorn Server Beta 3 or later, PowerShell is now an "optional component". 
   echo Install the latest LH server builds from \\winbuilds\release\longhorn.
   echo To get powershell, launch Server Manager--> Features --> Add Features --> Select Windows Powershell
   
   exit /b 1
)

set POWERSHELL_KEY=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell

if DEFINED WhatIf (
    echo would install PowerShell by calling %Installer%
) else (
    echo calling %Installer%
    call %Installer%

    echo Setting ExecutionPolicy to RemoteSigned.
    reg add %POWERSHELL_KEY% /v ExecutionPolicy /d RemoteSigned /f
)


exit /b 0
