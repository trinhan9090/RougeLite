@echo off
setlocal
set "APPDATA=%~dp0.local-data"
"%~dp0tools\godot\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0experiments\mugen_atyu" %*
exit /b %errorlevel%
