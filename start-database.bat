@echo off
setlocal
cd /d "%~dp0"

echo Checking Docker...
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running or is not installed.
    echo Start Docker Desktop, then run this file again.
    exit /b 1
)

echo Building the database image...
docker compose build db
if errorlevel 1 (
    echo Database image build failed.
    exit /b 1
)

echo Starting MariaDB...
docker compose up -d db
if errorlevel 1 (
    echo Database container failed to start.
    exit /b 1
)

echo Waiting for MariaDB to become ready...
set "READY="
for /l %%i in (1,1,30) do (
    docker compose exec -T db mariadb-admin ping -h 127.0.0.1 -u gamelord -pgamelord --silent >nul 2>&1
    if not errorlevel 1 (
        set "READY=1"
        goto :ready
    )
    "%SystemRoot%\System32\timeout.exe" /t 2 /nobreak >nul
)

if not defined READY (
    echo MariaDB did not become ready in time.
    docker compose logs --tail=40 db
    exit /b 1
)

:ready
echo MariaDB is ready. Verifying the schema...
docker compose exec -T db mariadb -u gamelord -pgamelord bs12 -e "SHOW TABLES;"
if errorlevel 1 (
    echo Database connection or schema verification failed.
    exit /b 1
)

echo.
echo Database started successfully.
echo Database: bs12
 echo User: gamelord
 echo Password: gamelord
 echo Docker hostname for the game container: db
endlocal
