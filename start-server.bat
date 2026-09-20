@echo off
setlocal
cd /d "%~dp0"

echo Starting Marrow server on port 6345...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-server.ps1" -Port 6345
if errorlevel 1 (
    echo Server failed to start.
    exit /b 1
)
