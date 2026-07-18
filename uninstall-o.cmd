@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall-o.ps1" %*
exit /b %errorlevel%
