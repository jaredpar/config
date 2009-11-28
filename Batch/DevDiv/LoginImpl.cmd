@echo off
REM This is called whenever I log into one of my devdiv machines.  SetVars
REM has already been called

set THIS_PATH=%~dp0
if "%THIS_PATH:~-1%" == "\" set THIS_PATH=%THIS_PATH:~0,-1%
pushd "%THIS_PATH%"

echo DevDiv LoginScript

if NOT "%RTM_MOUNT_DEVICE%" == "" (
    echo    Mounting DotNet RTM Sources
    net use %RTM_MOUNT_DEVICE% \\cpvsbuild\drops\whidbey\rtm\raw\50727.42\sources
)

if NOT "%REDBITS_MOUNT_DEVICE%" == "" (
    echo    Mounting RedBits Sources
    net use %REDBITS_MOUNT_DEVICE% \\ddindex2\sources\Vista.NetFX
)

popd
