@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== DISM OFFLINE /ScanHealth =====
echo PrÅft den Komponentenspeicher tiefer als /CheckHealth.
echo Kann Protokolle und temporare Dateien erstellen.
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
set "SCRATCH=%~dp0..\Scratch"
if /I not "%NOLS_SAVE_LOGS%"=="Y" set "SCRATCH=%TEMP%\ITW-DISM-Scratch"
if not exist "!SCRATCH!\" md "!SCRATCH!" >nul 2>&1
if not exist "!SCRATCH!\" (
    echo FEHLER: Scratch-Verzeichnis auf dem Toolkit-Laufwerk nicht schreibbar.
    exit /b 1
)
echo.
echo Ziel: !WIN!:\Windows
echo DISM /Image:!WIN!:\ /Cleanup-Image /ScanHealth
echo Scratch: !SCRATCH!
set "CONF="
set /p "CONF=PrÅfung starten? (Y/N): "
if /I not "!CONF!"=="Y" exit /b 0
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR DISM_SCAN
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
if defined LOGDIR (
 dism.exe /Image:!WIN!:\ /Cleanup-Image /ScanHealth "/ScratchDir:!SCRATCH!" "/LogPath:!LOGDIR!\DISM_Detail.log"
) else (
 dism.exe /Image:!WIN!:\ /Cleanup-Image /ScanHealth "/ScratchDir:!SCRATCH!"
)
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo DISM ScanHealth !WIN!: - Rueckgabecode !RC!
 echo Protokoll: "!LOGDIR!"
)
echo DISM-RÅckgabecode: !RC!
exit /b !RC!
