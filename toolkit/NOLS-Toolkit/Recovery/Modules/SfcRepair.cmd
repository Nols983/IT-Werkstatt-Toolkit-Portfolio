@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== SFC OFFLINE - REPARATUR =====
echo /scannow kann geschÅtzte Windows-Systemdateien ERSETZEN.
echo Vorher Backup/Image und Zielinstallation prÅfen.
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
set "BOOT="
call "%~dp0ChooseBootDir.cmd" BOOT !WIN!
if errorlevel 1 exit /b 1
call "%~dp0WriteTargetGuard.cmd" !WIN! DRIVE
if errorlevel 1 exit /b 1
call "%~dp0WriteTargetGuard.cmd" !BOOT! DRIVE
if errorlevel 1 exit /b 1
echo.
echo Zu reparieren: !WIN!:\Windows
echo Boot-Verz.   : !BOOT!:\
echo Befehl: sfc /scannow /offbootdir=!BOOT!:\ /offwindir=!WIN!:\Windows
echo.
set "CONF="
set /p "CONF=SFC-Reparatur starten? (Y/N): "
if /I not "!CONF!"=="Y" (
    echo Reparatur abgebrochen.
    exit /b 0
)
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR SFC_REPAIR
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
if defined LOGDIR (
 sfc.exe /scannow /offbootdir=!BOOT!:\ /offwindir=!WIN!:\Windows "/offlogfile=!LOGDIR!\SFC_Detail.log"
) else (
 sfc.exe /scannow /offbootdir=!BOOT!:\ /offwindir=!WIN!:\Windows
)
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo SFC Scannow !WIN!: - Rueckgabecode !RC!
 echo Protokoll: "!LOGDIR!"
)
echo SFC-RÅckgabecode: !RC!
exit /b !RC!
