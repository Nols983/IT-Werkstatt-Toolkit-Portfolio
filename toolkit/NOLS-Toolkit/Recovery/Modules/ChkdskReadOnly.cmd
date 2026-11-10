@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== CHKDSK STATUS (OHNE REPARATUR) =====
echo WICHTIG: CHKDSK ohne /F /R /X prft nur, repariert nicht.
echo Bei physisch defektem Laufwerk kann auch ein Lesetest belasten.
echo Vorher Daten sichern, wenn m”glich.
set "TARGET="
call "%~dp0ChooseDrive.cmd" TARGET
if errorlevel 1 exit /b 1
echo.
echo Ziel: %TARGET%:
echo Befehl: chkdsk %TARGET%:
set "CONFIRM="
set /p "CONFIRM=Prfung starten? (Y/N): "
if /I not "!CONFIRM!"=="Y" (
    echo Abgebrochen.
    exit /b 0
)
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR CHKDSK_CHECK
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
chkdsk.exe %TARGET%:
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo CHKDSK %TARGET%: - Rueckgabecode !RC!
 >>"!LOGDIR!\00_Ergebnis.txt" echo Live-Ausgabe stand in der Konsole; keine vollstaendige Mitschrift.
 echo Ergebnisprotokoll: "!LOGDIR!"
)
exit /b !RC!
