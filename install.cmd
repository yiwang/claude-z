@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0install.ps1" %*
exit /b %errorlevel%
