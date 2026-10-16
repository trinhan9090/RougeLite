@echo off
setlocal
rem Keep the same local settings directory as tools/launch.ps1.
set "APPDATA=%~dp0.local-data"
set "ROUGELITE_ENGINE=%~dp0tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%ROUGELITE_ENGINE%" (
    echo Godot was not found at "%ROUGELITE_ENGINE%".
    echo Extract the Godot 4.7.2 Windows portable archive into tools\godot.
    exit /b 1
)
"%ROUGELITE_ENGINE%" --path "%~dp0." %*
exit /b %errorlevel%
