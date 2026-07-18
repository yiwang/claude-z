@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0install-k.ps1" %*
exit /b %errorlevel%
