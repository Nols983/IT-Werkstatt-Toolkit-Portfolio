@echo off
setlocal EnableExtensions
rem NOLS IT Toolkit - Umgebungserkennung ohne Aenderung an Windows.
rem MiniNT wird von Windows PE und Windows RE typischerweise gesetzt.
reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control\MiniNT" >nul 2>&1
if not errorlevel 1 goto recovery
if /I "%SystemDrive%"=="X:" goto recovery
if exist "%~dp0NOLS-Toolkit-starten.cmd" (
    call "%~dp0NOLS-Toolkit-starten.cmd"
    exit /b %errorlevel%
)
echo FEHLER: Windows-Launcher nicht gefunden.
echo Erwartet: "%~dp0NOLS-Toolkit-starten.cmd"
exit /b 1

:recovery
call "%~dp0START-RECOVERY.cmd"
exit /b %errorlevel%
