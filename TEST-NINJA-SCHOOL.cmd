@ECHO OFF
SETLOCAL
CD /D "%~dp0"
TITLE Ninja School - Windows Local Test
ECHO =============================================
ECHO  NINJA SCHOOL - LOCAL OFFLINE TEST (WINDOWS)
ECHO =============================================
ECHO  Database and game port stay on 127.0.0.1.
ECHO.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-offline.ps1"
IF ERRORLEVEL 1 (
  ECHO.
  ECHO Setup failed. Read the error above, then rerun this file.
  PAUSE
  EXIT /B 1
)
ECHO.
ECHO Starting Java game server. Press Ctrl+C to stop.
CALL "%~dp0run.bat"
ECHO.
ECHO Game server stopped. Database stays available for next test.
PAUSE
