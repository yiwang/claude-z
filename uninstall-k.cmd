@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall-k.ps1" %*
exit /b %errorlevel%
