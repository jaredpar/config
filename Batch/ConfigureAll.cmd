@echo off

for %%i in (Configure\*) do (
    echo Configuring %%i
    call "%%i"
)

