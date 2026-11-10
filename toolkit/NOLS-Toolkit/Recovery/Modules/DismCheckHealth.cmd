@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== DISM OFFLINE CHECKHEALTH (KEINE REPARATUR) =====
echo Dieser Modus fragt den registrierten Komponentenstatus ab.
echo Kein /RestoreHealth oder /Online. Es k”nnen Logs im Temp entstehen.
echo WinPE-DISM-Version muss mit dem Ziel-Windows kompatibel sein.
set "TARGET="
call "%~dp0ChooseDrive.cmd" TARGET
if errorlevel 1 exit /b 1
if not exist "%TARGET%:\Windows\System32\Config\SYSTEM" (
    echo Kein erreichbares Windows-System unter %TARGET%:\Windows gefunden.
    exit /b 1
)
echo.
echo Ziel: %TARGET%:\Windows
echo Befehl: dism /Image:%TARGET%:\ /Cleanup-Image /CheckHealth
set "CONFIRM="
set /p "CONFIRM=Prfung starten? (Y/N): "
if /I not "!CONFIRM!"=="Y" (
    echo Abgebrochen.
    exit /b 0
)
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR DISM_CHECK
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
if defined LOGDIR (
 dism.exe /Image:%TARGET%:\ /Cleanup-Image /CheckHealth "/LogPath:!LOGDIR!\DISM_Detail.log"
) else (
 dism.exe /Image:%TARGET%:\ /Cleanup-Image /CheckHealth
)
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo DISM CheckHealth fuer %TARGET%: - Rueckgabecode !RC!
 echo Protokoll: "!LOGDIR!"
)
exit /b !RC!
