@ECHO OFF
SETLOCAL
CD /D "%~dp0"
ECHO Stop the running game server with Ctrl+C in the test window first.
ECHO Stopping local MariaDB container (NO DATA DELETION)...
docker compose stop db
IF ERRORLEVEL 1 (
  ECHO Error stopping MariaDB. Ensure Docker Desktop is running.
  PAUSE
  EXIT /B 1
)
ECHO Local DB stopped; persistent Docker volume has NOT been deleted.
PAUSE
