@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall.ps1" %*
exit /b %errorlevel%
