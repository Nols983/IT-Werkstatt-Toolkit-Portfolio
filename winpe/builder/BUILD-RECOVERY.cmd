@echo off
setlocal EnableExtensions DisableDelayedExpansion
title IT-Werkstatt Recovery - WinPE Builder
if /I "%~1"=="--build" goto BUILD
if /I "%~1"=="--check" goto CHECK
:CHECK
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD-RECOVERY.ps1"
set "RC=%ERRORLEVEL%"
goto END
:BUILD
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD-RECOVERY.ps1" -Build
set "RC=%ERRORLEVEL%"
:END
echo.
if not "%RC%"=="0" echo Build oder Vorpruefung fehlgeschlagen - Details stehen oben.
pause
exit /b %RC%
