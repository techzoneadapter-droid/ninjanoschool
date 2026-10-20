@ECHO OFF
SETLOCAL
CD /D "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\status-offline.ps1"
PAUSE
