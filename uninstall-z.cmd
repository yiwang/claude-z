@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall-z.ps1" %*
exit /b %errorlevel%
