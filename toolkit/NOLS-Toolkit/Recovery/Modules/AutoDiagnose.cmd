@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem NOLS IT TOOLKIT v1.8.6: automatisierte, nicht reparierende Offline-Diagnose.
rem ACHTUNG: Pruefprogramme koennen temporaere Logs/Statusdaten schreiben.
rem KEIN /f, /r, /scannow, /RestoreHealth, BCDBoot, Bootrec.
echo.
echo ================================================================
echo             IT-WERKSTATT - AUTOMATISCHE DIAGNOSE
echo ================================================================
echo.
echo  Schritte: Volume-Liste und einmalige Windows-Auswahl
echo           CHKDSK ohne /f und DISM CheckHealth
echo           Vollmodus: zus„tzlich DISM ScanHealth und SFC
echo           Ergebnisdateien und Reparatur-Hinweise
 echo.
echo  Hinweis: Es werden KEINE Reparaturen gestartet.
echo  Auch lesende Scans k”nnen einen defekten Datentr„ger belasten.
echo  Bei Klackern, Abbrchen, I/O-Fehlern: erst Daten/Image sichern.
echo.
echo   [1] Schnell: CHKDSK + DISM CheckHealth
echo   [2] Vollst„ndig: zus„tzlich DISM ScanHealth + SFC
echo   [0] Abbrechen
set "MODE="
set /p "MODE=Auswahl: "
if "%MODE%"=="0" exit /b 0
if not "%MODE%"=="1" if not "%MODE%"=="2" (
    echo Ungltige Auswahl.
    exit /b 1
)
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
set "BOOT=%WIN%"
set "DSRC=SKIP"
set "SFRC=SKIP"
rem Ein Windows-Laufwerksbuchstabe fuer alle vier Pruefungen.
rem SFC nimmt dieses Root als Bootpfad, bei Bedarf Einzeldiagnose nutzen.
echo.
echo Gew„hlte Windows-Installation: %WIN%:\Windows
echo SFC-Bootpfad: %BOOT%:\ (automatischer Standard)
echo.
echo Diese Untersuchung nutzt die ausgew„hlte Installation, NICHT /Online.
echo Ziel prfen! BitLocker muss bei Bedarf bereits entsperrt sein.
set "GO="
set /p "GO=Diagnose starten? (Y/N): "
if /I not "%GO%"=="Y" (
    echo Abgebrochen.
    exit /b 0
)

rem Logverzeichnis liegt bewusst auf dem Toolkit-Laufwerk, nicht auf C:.
rem N: nur temporaere Logs in der WinPE-RAM-Umgebung fuer Auswertung.
set "LOGBASE=%~dp0..\Logs"
if /I "%NOLS_SAVE_LOGS%"=="N" (
 set "LOGBASE=%TEMP%\NOLS-Toolkit-Temp"
 if not defined TEMP set "LOGBASE=%SystemRoot%\Temp\NOLS-Toolkit-Temp"
)
if not exist "%LOGBASE%\" md "%LOGBASE%" >nul 2>&1
if not exist "%LOGBASE%\" (
    echo ABBRUCH: USB-Logverzeichnis nicht erreichbar oder nicht schreibbar.
    exit /b 1
)
set "LOGDIR=%LOGBASE%\AUTO_%RANDOM%_%RANDOM%"
if exist "%LOGDIR%\" (
    echo ABBRUCH: Logverzeichnis existiert bereits. Erneut versuchen.
    exit /b 1
)
md "%LOGDIR%" >nul 2>&1
if not exist "%LOGDIR%\" (
    echo ABBRUCH: Logverzeichnis kann nicht erstellt werden.
    exit /b 1
)
> "%LOGDIR%\schreibtest.tmp" echo test
if errorlevel 1 (
    echo ABBRUCH: Logverzeichnis ist nicht schreibbar.
    exit /b 1
)
del /q "%LOGDIR%\schreibtest.tmp" >nul 2>&1
set "SUMMARY=%LOGDIR%\00_Ergebnis.txt"
> "%SUMMARY%" echo IT-WERKSTATT AUTO-DIAGNOSE v2.4.2
>> "%SUMMARY%" echo Ziel-Windows: %WIN%:\Windows
>> "%SUMMARY%" echo SFC-Bootpfad: %BOOT%:\ (automatischer Standard)
>> "%SUMMARY%" echo Diagnose-Modus: %MODE%
>> "%SUMMARY%" echo Keine Reparaturbefehle ausgefuehrt.
>> "%SUMMARY%" echo Rueckgabecodes sind keine alleinige Gesund-/Defektbewertung.
>> "%SUMMARY%" echo.

set "SCRATCH=%~dp0..\Logs\Scratch"
if /I "%NOLS_SAVE_LOGS%"=="N" set "SCRATCH=%TEMP%\ITW-DISM-Scratch"
if not exist "%SCRATCH%\" md "%SCRATCH%" >nul 2>&1
if not exist "%SCRATCH%\" (
    echo ABBRUCH: DISM-Scratchverzeichnis nicht verfgbar.
    exit /b 1
)

echo.
echo ===== [1] CHKDSK: Lesen des Dateisystemstatus =====
echo Der Scan kann dauern. Ausgabe nach Abschluss.
if not exist "%SystemRoot%\System32\chkdsk.exe" goto skip_chkdsk
"%SystemRoot%\System32\chkdsk.exe" %WIN%: > "%LOGDIR%\10_CHKDSK.txt" 2>&1
set "CHRC=%errorlevel%"
type "%LOGDIR%\10_CHKDSK.txt"
>> "%SUMMARY%" echo CHKDSK: Rueckgabecode %CHRC% - Details 10_CHKDSK.txt
if not "%CHRC%"=="0" >> "%SUMMARY%" echo   Hinweis: CHKDSK-Ausgabe sorgfaeltig pruefen, ggf. Datensicherung vor /f.
goto do_dism_check
:skip_chkdsk
set "CHRC=NICHT_VERFUEGBAR"
>> "%SUMMARY%" echo CHKDSK: NICHT VERFUEGBAR
 echo WARNUNG: CHKDSK ist in dieser Umgebung nicht vorhanden.

:do_dism_check
echo.
echo ===== [2] DISM: Komponentenstatus CheckHealth =====
echo Der Scan kann dauern. Ausgabe nach Abschluss.
if not exist "%SystemRoot%\System32\dism.exe" goto skip_dism_check
"%SystemRoot%\System32\dism.exe" /Image:%WIN%:\ /Cleanup-Image /CheckHealth "/ScratchDir:%SCRATCH%" "/LogPath:%LOGDIR%\20_DISM_Detail.log" > "%LOGDIR%\20_DISM_CheckHealth.txt" 2>&1
set "DCRC=%errorlevel%"
type "%LOGDIR%\20_DISM_CheckHealth.txt"
>> "%SUMMARY%" echo DISM CheckHealth: Rueckgabecode %DCRC% - Details 20_DISM_CheckHealth.txt
if not "%DCRC%"=="0" >> "%SUMMARY%" echo   Hinweis: DISM konnte ggf. nicht pruefen. Version/Log/BitLocker pruefen.
goto maybe_full
:skip_dism_check
set "DCRC=NICHT_VERFUEGBAR"
>> "%SUMMARY%" echo DISM CheckHealth: NICHT VERFUEGBAR
 echo WARNUNG: DISM ist in dieser Umgebung nicht vorhanden.

:maybe_full
if not "%MODE%"=="2" goto end_summary

echo.
echo ===== [3] DISM: ausfhrlicher ScanHealth =====
echo Dieser Vorgang kann l„nger dauern. Ausgabe nach Abschluss.
if not exist "%SystemRoot%\System32\dism.exe" goto skip_scan
"%SystemRoot%\System32\dism.exe" /Image:%WIN%:\ /Cleanup-Image /ScanHealth "/ScratchDir:%SCRATCH%" "/LogPath:%LOGDIR%\30_DISM_Scan_Detail.log" > "%LOGDIR%\30_DISM_ScanHealth.txt" 2>&1
set "DSRC=%errorlevel%"
type "%LOGDIR%\30_DISM_ScanHealth.txt"
>> "%SUMMARY%" echo DISM ScanHealth: Rueckgabecode %DSRC% - Details 30_DISM_ScanHealth.txt
if not "%DSRC%"=="0" >> "%SUMMARY%" echo   Hinweis: Scan nicht erfolgreich, Details und Tool-Version pruefen.
goto do_sfc
:skip_scan
set "DSRC=NICHT_VERFUEGBAR"
>> "%SUMMARY%" echo DISM ScanHealth: NICHT VERFUEGBAR
 echo WARNUNG: DISM fehlt.

:do_sfc
echo.
echo ===== [4] SFC: Systemdateien nur verifizieren =====
echo Dieser Vorgang kann l„nger dauern. Ausgabe nach Abschluss.
if not exist "%SystemRoot%\System32\sfc.exe" goto skip_sfc
"%SystemRoot%\System32\sfc.exe" /verifyonly /offbootdir=%BOOT%:\ /offwindir=%WIN%:\Windows "/offlogfile=%LOGDIR%\40_SFC_Detail.log" > "%LOGDIR%\40_SFC_VerifyOnly.txt" 2>&1
set "SFRC=%errorlevel%"
type "%LOGDIR%\40_SFC_VerifyOnly.txt"
>> "%SUMMARY%" echo SFC VerifyOnly: Rueckgabecode %SFRC% - Details 40_SFC_VerifyOnly.txt
if not "%SFRC%"=="0" >> "%SUMMARY%" echo   Hinweis: Ergebnistext und korrekten Bootpfad pruefen.
goto end_summary
:skip_sfc
set "SFRC=NICHT_VERFUEGBAR"
>> "%SUMMARY%" echo SFC VerifyOnly: NICHT VERFUEGBAR
 echo WARNUNG: SFC fehlt.

:end_summary
set "STATUS=%LOGDIR%\80_STATUS.ini"
> "%STATUS%" echo MODE=DIAG
>> "%STATUS%" echo CHKDSK=%CHRC%
>> "%STATUS%" echo DISM_CHECK=%DCRC%
>> "%STATUS%" echo DISM_SCAN=%DSRC%
>> "%STATUS%" echo SFC_VERIFY=%SFRC%
>> "%SUMMARY%" echo.
>> "%SUMMARY%" echo EMPFEHLUNGEN - BITTE DIE ORIGINALAUSGABEN LESEN:
>> "%SUMMARY%" echo - Status und Fehlermeldungen in CHKDSK/DISM/SFC-Textdateien beurteilen.
>> "%SUMMARY%" echo - CHKDSK-Fehler: Daten sichern; /f nur gezielt nach Risikoabwaegung.
>> "%SUMMARY%" echo - DISM-Komponentenschaeden: passende Quelle fuer /RestoreHealth vorbereiten.
>> "%SUMMARY%" echo - SFC-Fehler: Ziel-Bootpfad pruefen; nach Backup ggf. /scannow.
>> "%SUMMARY%" echo - Boot-/BCD-Fehler werden in diesem Lauf NICHT repariert.
>> "%SUMMARY%" echo - Rueckgabecode 0 beweist NICHT, dass Windows problemlos startet.
>> "%SUMMARY%" echo - DISM/SFC koennen trotz Diagnosemodus Temp-/Logdaten erzeugen.
echo.
echo =============== ZUSAMMENFASSUNG ===============
type "%SUMMARY%"
echo.
if /I not "%NOLS_SAVE_LOGS%"=="N" echo Vollst„ndige Protokolle: "%LOGDIR%"
if /I not "%NOLS_SAVE_LOGS%"=="N" echo HINWEIS: Die Logs k”nnen Rechnerdaten / Pfade enthalten.
echo Keine automatische Reparatur gestartet.
if "%MODE%"=="2" call "%~dp0BootDiagnose.cmd" AUTO "%WIN%" "%LOGDIR%"
call "%~dp0AnalyseResults.cmd" "%LOGDIR%"
if /I "%NOLS_SAVE_LOGS%"=="N" (
 rd /s /q "%LOGDIR%" >nul 2>&1
 echo Keine dauerhaften Toolkit-Logs gespeichert.
)
exit /b 0
