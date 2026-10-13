@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\build_windows.ps1"
if errorlevel 1 (
 echo BUILD FAILED. Keep the error text above and give it to your teacher.
) else (
 echo Build complete. Your playable ZIP is in the exports folder.
)
pause
