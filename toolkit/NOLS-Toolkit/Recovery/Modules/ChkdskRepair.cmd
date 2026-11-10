@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== CHKDSK /F - DATEISYSTEM REPARIEREN =====
echo ACHTUNG: /f verÑndert Dateisystem-Metadaten und kann
echo bei beschÑdigten DatentrÑgern Datenverluste verursachen.
echo Bei SSD/HDD-Defekt zuerst Image erstellen - NICHT /r nutzen.
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
call "%~dp0WriteTargetGuard.cmd" !WIN! DRIVE
if errorlevel 1 exit /b 1
echo.
echo Zu reparierendes Volume: !WIN!:
echo Befehl: chkdsk !WIN!: /f
echo WICHTIG: Ziel darf nicht das Recovery-USB sein.
echo.
set "CONF="
set /p "CONF=CHKDSK-Reparatur starten? (Y/N): "
if /I not "!CONF!"=="Y" (
    echo Reparatur abgebrochen.
    exit /b 0
)
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR CHKDSK_REPAIR
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
chkdsk.exe !WIN!: /f
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo CHKDSK !WIN!: /f - Rueckgabecode !RC!
 >>"!LOGDIR!\00_Ergebnis.txt" echo Live-Ausgabe stand in der Konsole; keine vollstaendige Mitschrift.
 echo Ergebnisprotokoll: "!LOGDIR!"
)
echo CHKDSK-RÅckgabecode: !RC!
exit /b !RC!
