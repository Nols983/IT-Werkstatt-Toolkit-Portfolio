@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== DISM OFFLINE /RestoreHealth =====
echo ACHTUNG: Reparatur des Komponentenspeichers verÑndert das Ziel.
echo Quelle sollte zur Windows-Version, Edition und Architektur passen.
echo Ventoy-ISOs sind nicht automatisch Reparaturquellen.
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
call "%~dp0WriteTargetGuard.cmd" !WIN! DRIVE
if errorlevel 1 exit /b 1
set "SCRATCH=%~dp0..\Scratch"
if /I not "%NOLS_SAVE_LOGS%"=="Y" set "SCRATCH=%TEMP%\ITW-DISM-Scratch"
if not exist "!SCRATCH!\" md "!SCRATCH!" >nul 2>&1
if not exist "!SCRATCH!\" (
    echo FEHLER: Scratch-Verzeichnis auf dem Toolkit-Laufwerk nicht schreibbar.
    exit /b 1
)
echo.
echo Reparaturquelle:
echo   [1] Ohne explizite Quelle versuchen (in WinPE oft erfolglos)
echo   [2] Passende Quelle angeben, z.B. E:\Windows oder WIM:E:\install.wim:6
echo   [0] Abbrechen
set "A="
set /p "A=Auswahl: "
if "!A!"=="0" exit /b 0
set "SRC="
if "!A!"=="2" (
    set /p "SRC=Quellpfad (KEINE ISO-Datei): "
    if not defined SRC (
        echo Keine Quelle angegeben. Abbruch.
        exit /b 1
    )
) else (
    if not "!A!"=="1" exit /b 1
)
echo.
echo Ziel : !WIN!:\Windows
if defined SRC (
    echo Quelle: !SRC!
    echo Befehl: DISM /Image:!WIN!:\ /Cleanup-Image /RestoreHealth /Source:QUELLE
) else (
    echo Keine Quelle. DISM verwendet konfigurierte Standardquellen.
    echo Befehl: DISM /Image:!WIN!:\ /Cleanup-Image /RestoreHealth
)
echo Scratch: !SCRATCH!
echo.
set "CONF="
set /p "CONF=DISM-Reparatur starten? (Y/N): "
if /I not "!CONF!"=="Y" (
    echo Reparatur abgebrochen.
    exit /b 0
)
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR DISM_REPAIR
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
set "LP="
if defined LOGDIR set "LP=/LogPath:!LOGDIR!\DISM_Detail.log"
if defined SRC (
    dism.exe /Image:!WIN!:\ /Cleanup-Image /RestoreHealth "/Source:!SRC!" "/ScratchDir:!SCRATCH!" !LP!
) else (
    dism.exe /Image:!WIN!:\ /Cleanup-Image /RestoreHealth "/ScratchDir:!SCRATCH!" !LP!
)
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo DISM RestoreHealth !WIN!: - Rueckgabecode !RC!
 echo Protokoll: "!LOGDIR!"
)
echo DISM-RÅckgabecode: !RC!
exit /b !RC!
