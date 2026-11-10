@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem NOLS v1.8: offline, ein Windows-Buchstabe, nur explizite Reparatur.
rem Kein /Online, kein /r, kein Bootrec/BCDBoot, keine EFI-Manipulation.
chcp 850 >nul 2>&1
echo.
echo ================================================================
echo                 IT-WERKSTATT - AUTO-REPARATUR
echo ================================================================
echo.
echo  [1] Nur CHKDSK /f - Dateisystem reparieren
echo  [2] DISM /RestoreHealth, danach SFC /scannow
echo  [3] Vollst„ndig: CHKDSK /f, DISM /RestoreHealth, SFC /scannow
echo  [0] Abbrechen
echo.
echo  ACHTUNG: Diese Befehle ver„ndern Daten auf der Zielpartition.
echo  Bei Hardwareverdacht zuerst ein Image oder Backup erstellen.
echo  DISM kann ohne passende Windows-Reparaturquelle fehlschlagen.
echo  Das Skript stoppt bei problematischen Rckgabecodes.
echo.
set "MODE="
set /p "MODE=Auswahl: "
if "!MODE!"=="0" exit /b 0
if not "!MODE!"=="1" if not "!MODE!"=="2" if not "!MODE!"=="3" (
    echo Ungltige Auswahl.
    exit /b 1
)

rem Schutz: Automatikreparatur nur in WinPE / WinRE starten.
reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control\MiniNT" >nul 2>&1
if not errorlevel 1 goto PE_OK
if /I "%SystemDrive%"=="X:" goto PE_OK
echo ABBRUCH: Die Automatikreparatur ben”tigt WinPE oder WinRE.
exit /b 1
:PE_OK

set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
call "%~dp0WriteTargetGuard.cmd" !WIN! DRIVE
if errorlevel 1 exit /b 1
if not exist "%WIN%:\Windows\System32\Config\SYSTEM" (
    echo ABBRUCH: Die Windows-Installation ist nicht lesbar.
    exit /b 1
)
rem N: nur temporaere Logs in der WinPE-RAM-Umgebung fuer Auswertung.
set "LOGBASE=%~dp0..\Logs"
if /I "%NOLS_SAVE_LOGS%"=="N" (
 set "LOGBASE=%TEMP%\NOLS-Toolkit-Temp"
 if not defined TEMP set "LOGBASE=%SystemRoot%\Temp\NOLS-Toolkit-Temp"
)
if not exist "%LOGBASE%\" md "%LOGBASE%" >nul 2>&1
if not exist "%LOGBASE%\" (
    echo ABBRUCH: USB-Protokollverzeichnis nicht erreichbar.
    exit /b 1
)
set "LOGDIR=%LOGBASE%\REPAIR_%RANDOM%_%RANDOM%"
if exist "%LOGDIR%\" (
    echo ABBRUCH: Logordner existiert bereits. Vorgang erneut starten.
    exit /b 1
)
md "%LOGDIR%" >nul 2>&1
if not exist "%LOGDIR%\" (
    echo ABBRUCH: Der Logordner konnte nicht erstellt werden.
    exit /b 1
)
> "%LOGDIR%\schreibtest.tmp" echo Schreibtest
if errorlevel 1 (
    echo ABBRUCH: USB-Protokollordner nicht schreibbar.
    exit /b 1
)
del /q "%LOGDIR%\schreibtest.tmp" >nul 2>&1
set "SUMMARY=%LOGDIR%\00_Ergebnis.txt"
set "CHRC=SKIP"
set "DRC=SKIP"
set "SRC=SKIP"
> "%SUMMARY%" echo IT-WERKSTATT AUTO-REPARATUR v2.4.2
>> "%SUMMARY%" echo Windows-Ziel: %WIN%:\Windows
>> "%SUMMARY%" echo Modus: %MODE%
>> "%SUMMARY%" echo SFC-Bootpfad: %WIN%:\ (automatischer Standard)
>> "%SUMMARY%" echo Hinweis: Details bei DISM/SFC in eigenen Logdateien.

set "SCRATCH=%~dp0..\Logs\Scratch"
if /I "%NOLS_SAVE_LOGS%"=="N" set "SCRATCH=%TEMP%\ITW-DISM-Scratch"
if not exist "%SCRATCH%\" md "%SCRATCH%" >nul 2>&1
if not exist "%SCRATCH%\" (
    echo ABBRUCH: Scratch-Ordner auf dem USB-Laufwerk fehlt.
    exit /b 1
)

echo.
echo ================================================================
echo  ZIEL: %WIN%:\Windows
echo  TOOLKIT: %~d0
if /I not "%NOLS_SAVE_LOGS%"=="N" echo  Protokoll: "%LOGDIR%"
echo ================================================================
echo.
if "%MODE%"=="1" echo  Geplant: CHKDSK %WIN%: /f
if "%MODE%"=="2" (
    echo  Geplant: DISM /Image:%WIN%:\ /Cleanup-Image /RestoreHealth
    echo           SFC /scannow /offbootdir=%WIN%:\ /offwindir=%WIN%:\Windows
)
if "%MODE%"=="3" (
    echo  Geplant: CHKDSK %WIN%: /f
    echo           DISM /Image:%WIN%:\ /Cleanup-Image /RestoreHealth
    echo           SFC /scannow /offbootdir=%WIN%:\ /offwindir=%WIN%:\Windows
)
echo.
echo  Prfe, ob %WIN%: die richtige interne Windows-Partition ist.
echo  NICHT fortfahren, wenn BitLocker gesperrt ist oder das Laufwerk
 echo  physisch defekt sein k”nnte. Der Vorgang ist nicht rckg„ngig zu machen.
echo.
set "CONF="
set /p "CONF=Reparatur jetzt ausfhren? (Y/N): "
if /I not "!CONF!"=="Y" (
    echo Abgebrochen. Es wurde keine Reparatur ausgefhrt.
    >> "%SUMMARY%" echo Vor Žnderungen abgebrochen.
    if /I "%NOLS_SAVE_LOGS%"=="N" rd /s /q "%LOGDIR%" >nul 2>&1
    exit /b 0
)
>> "%SUMMARY%" echo Best„tigung erteilt. Reparaturen gestartet.

if "%MODE%"=="1" goto RUN_CHKDSK
if "%MODE%"=="3" goto RUN_CHKDSK
goto RUN_DISM

:RUN_CHKDSK
echo.
echo ===== [1] CHKDSK %WIN%: /f - Dateisystem reparieren =====
if not exist "%SystemRoot%\System32\chkdsk.exe" goto CHKDSK_MISSING
rem Bewusst ohne stdout-Umleitung: eventuelle Rckfragen bleiben sichtbar.
"%SystemRoot%\System32\chkdsk.exe" %WIN%: /f
set "CHRC=%errorlevel%"

>> "%SUMMARY%" echo CHKDSK /f: Rckgabecode %CHRC%.
if "%CHRC%"=="0" goto CHKDSK_OK
if "%CHRC%"=="1" goto CHKDSK_OK
echo ABBRUCH: CHKDSK meldet Code %CHRC%. Kein weiterer Reparaturschritt.
>> "%SUMMARY%" echo AUTOMATIK GESTOPPT: CHKDSK-Ausgabe und Datentr„ger prfen.
goto FINISH_ERROR
:CHKDSK_MISSING
echo ABBRUCH: CHKDSK ist nicht verfgbar.
>> "%SUMMARY%" echo FEHLER: CHKDSK nicht verfgbar.
goto FINISH_ERROR
:CHKDSK_OK
if "%MODE%"=="1" goto FINISH_OK
goto RUN_DISM

:RUN_DISM
echo.
echo ===== [2] DISM - Offline-Komponentenspeicher reparieren =====
if not exist "%SystemRoot%\System32\dism.exe" goto DISM_MISSING
rem DISM gibt Fortschritt live aus; Detail-Log liegt auf dem Toolkit-Laufwerk.
"%SystemRoot%\System32\dism.exe" /Image:%WIN%:\ /Cleanup-Image /RestoreHealth "/ScratchDir:%SCRATCH%" "/LogPath:%LOGDIR%\20_DISM_Detail.log"
set "DRC=%errorlevel%"

>> "%SUMMARY%" echo DISM /RestoreHealth: Rckgabecode %DRC%.
if "%DRC%"=="0" goto RUN_SFC
echo ABBRUCH: DISM ist fehlgeschlagen. SFC wird nicht automatisch gestartet.
echo Falls eine Reparaturquelle fehlt: Einzelmodul DISM nutzen.
>> "%SUMMARY%" echo AUTOMATIK GESTOPPT: DISM-Log prfen. Quelle eventuell erforderlich.
goto FINISH_ERROR
:DISM_MISSING
echo ABBRUCH: DISM ist nicht verfgbar.
>> "%SUMMARY%" echo FEHLER: DISM nicht verfgbar.
goto FINISH_ERROR

:RUN_SFC
echo.
echo ===== [3] SFC - Offline-Systemdateien reparieren =====
if not exist "%SystemRoot%\System32\sfc.exe" goto SFC_MISSING
rem Nur ein Zielbuchstabe: /offbootdir = Windows-Root (typischer Standard).
rem Falls Bootverzeichnis abweicht: SFC-Einzelmodul bietet dessen Auswahl.
"%SystemRoot%\System32\sfc.exe" /scannow /offbootdir=%WIN%:\ /offwindir=%WIN%:\Windows "/offlogfile=%LOGDIR%\30_SFC_Detail.log"
set "SRC=%errorlevel%"

>> "%SUMMARY%" echo SFC /scannow: Rckgabecode %SRC%.
if "%SRC%"=="0" goto FINISH_OK
echo HINWEIS: SFC meldet Code %SRC%. Die Ausgabe muss geprft werden.
>> "%SUMMARY%" echo HINWEIS: SFC-Ergebnistext lesen; Bootpfad eventuell abweichend.
goto FINISH_ERROR
:SFC_MISSING
echo ABBRUCH: SFC ist nicht verfgbar.
>> "%SUMMARY%" echo FEHLER: SFC nicht verfgbar.
goto FINISH_ERROR

:FINISH_OK
>> "%SUMMARY%" echo Durchlauf abgeschlossen. Originalmeldungen trotzdem prfen.
set "RESULT=0"
goto FINISH
:FINISH_ERROR
>> "%SUMMARY%" echo Durchlauf nicht vollst„ndig erfolgreich. Keine weitere Automatik.
set "RESULT=1"
:FINISH
> "%LOGDIR%\80_STATUS.ini" echo MODE=REPAIR
>> "%LOGDIR%\80_STATUS.ini" echo CHKDSK=%CHRC%
>> "%LOGDIR%\80_STATUS.ini" echo DISM_RESTORE=%DRC%
>> "%LOGDIR%\80_STATUS.ini" echo SFC_REPAIR=%SRC%
echo.
echo ========================= ERGEBNIS =============================
type "%SUMMARY%"
echo.
if /I not "%NOLS_SAVE_LOGS%"=="N" echo Protokolle: "%LOGDIR%"
echo Reparaturausgaben bleiben live sichtbar; Details ber Rckgabecodes/Logs.
echo DISM/SFC k”nnen zus„tzliche Protokolle auf dem Zielsystem erzeugen.
echo Eine erfolgreiche Reparatur garantiert keinen Windows-Start.
call "%~dp0AnalyseResults.cmd" "%LOGDIR%"
if /I "%NOLS_SAVE_LOGS%"=="N" (
 rd /s /q "%LOGDIR%" >nul 2>&1
 echo Keine dauerhaften Toolkit-Logs gespeichert.
)
exit /b %RESULT%
