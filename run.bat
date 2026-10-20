@ECHO OFF
SETLOCAL
PUSHD "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-server.ps1"
SET "NSO_EXIT=%ERRORLEVEL%"
POPD
EXIT /B %NSO_EXIT%
