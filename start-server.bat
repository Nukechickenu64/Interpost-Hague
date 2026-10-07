@echo off
setlocal
cd /d "%~dp0"

if defined TTS_HTTP_URL if not "%TTS_HTTP_URL%"=="http://127.0.0.1:5000" goto external_tts

where docker >nul 2>&1
if errorlevel 1 (
    echo Docker is not installed or is not on PATH. Install Docker Desktop to start local TTS.
    exit /b 1
)

docker compose version >nul 2>&1
if errorlevel 1 (
    echo Docker Compose is not available. Install a recent Docker Desktop version.
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo Starting Docker Desktop for local TTS...
    docker desktop start
    if errorlevel 1 (
        echo Docker could not start. Start Docker Desktop with the Linux container engine and retry.
        exit /b 1
    )
)

echo Building and starting the local TTS service...
docker compose up -d --build --wait --wait-timeout 120 tts
if errorlevel 1 (
    echo TTS did not become ready. See "docker compose logs tts".
    exit /b 1
)
goto start_game

:external_tts
echo Using the configured external TTS service.

:start_game
echo Starting Interpost-Hague server on port 6345...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-server.ps1" -Port 6345
if errorlevel 1 (
    echo Server failed to start.
    exit /b 1
)
