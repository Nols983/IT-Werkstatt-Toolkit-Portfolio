@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem NOLS v1.8.1: konservative Auswertung nur der eigenen strukturierten Logs.
set "LOGBASE=%~dp0..\Logs"
set "LOGDIR=%~1"
if defined LOGDIR goto HAVE_DIR
echo.
echo =================== LOG-AUSWERTUNG =============================
echo Verfgbare Durchl„ufe in: "!LOGBASE!"
if not exist "!LOGBASE!\" (
 echo Noch keine Logs vorhanden.
 exit /b 1
)
dir /B /AD "!LOGBASE!" 2>nul
set "NAME="
set /p "NAME=Ordnername eines AUTO-/REPAIR-Laufs (Enter=Abbruch): "
if not defined NAME exit /b 0
rem Nur Ordnernamen aus A-Z, 0-9, Unterstrich, Punkt, Bindestrich.
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-." %%A in ("!NAME!") do (
 echo Ungltiger Ordnername.
 exit /b 1
)
set "LOGDIR=!LOGBASE!\!NAME!"
:HAVE_DIR
if not exist "!LOGDIR!\80_STATUS.ini" (
 echo Keine AUTO-/REPAIR-Statusdatei unter: "!LOGDIR!"
 echo Alte Logs enthalten oft nur Text und sind schwer auswertbar.
 exit /b 1
)
set "CH=SKIP"
set "DC=SKIP"
set "DS=SKIP"
set "SV=SKIP"
set "DR=SKIP"
set "SR=SKIP"
set "MODE=UNBEKANNT"
for /f "usebackq tokens=1,* delims==" %%A in ("!LOGDIR!\80_STATUS.ini") do (
 if /I "%%A"=="MODE" set "MODE=%%B"
 if /I "%%A"=="CHKDSK" set "CH=%%B"
 if /I "%%A"=="DISM_CHECK" set "DC=%%B"
 if /I "%%A"=="DISM_SCAN" set "DS=%%B"
 if /I "%%A"=="SFC_VERIFY" set "SV=%%B"
 if /I "%%A"=="DISM_RESTORE" set "DR=%%B"
 if /I "%%A"=="SFC_REPAIR" set "SR=%%B"
)
set "OUT=!LOGDIR!\90_Empfehlungen.txt"
>"!OUT!" echo IT-WERKSTATT - ERGEBNISAUSWERTUNG
>>"!OUT!" echo Modus: !MODE!
>>"!OUT!" echo ==============================================================
>>"!OUT!" echo Regeln: Nur Indizien, keine automatische Fehlerdiagnose.
>>"!OUT!" echo Originalausgaben und Ger„te-Zustand haben Vorrang.
>>"!OUT!" echo.
if /I "!CH!"=="SKIP" goto DISM_CHECK
if "!CH!"=="0" (
 >>"!OUT!" echo CHKDSK: Code 0 - laut Exitcode keine Dateisystemfehler.
) else if "!CH!"=="1" (
 >>"!OUT!" echo CHKDSK: Code 1 - Fehler gefunden und behoben; Details prfen.
) else if "!CH!"=="2" (
 >>"!OUT!" echo CHKDSK: Code 2 - Ergebnis NICHT eindeutig, ohne /f nicht repariert.
 >>"!OUT!" echo   Empfehlung: CHKDSK-Text lesen; vor Reparatur Daten sichern.
) else if "!CH!"=="3" (
 >>"!OUT!" echo CHKDSK: Code 3 - Prfung/Reparatur nicht erfolgreich.
 >>"!OUT!" echo   Empfehlung: Datentr„ger/BitLocker/Dateisystem untersuchen.
) else (
 >>"!OUT!" echo CHKDSK: Rckgabewert !CH! - manuell prfen.
)
:DISM_CHECK
if /I "!DC!"=="SKIP" goto DISM_SCAN
if "!DC!"=="0" (
 >>"!OUT!" echo DISM CheckHealth: Programm erfolgreich, Ergebnistext entscheidend.
) else (
 >>"!OUT!" echo DISM CheckHealth: Code !DC! - Prfung fehlgeschlagen/unklar.
 >>"!OUT!" echo   Empfehlung: Image-Pfad, BitLocker, DISM-Log/Version prfen.
)
call :DISM_TEXT "!LOGDIR!\20_DISM_CheckHealth.txt" "DISM CheckHealth"
:DISM_SCAN
if /I "!DS!"=="SKIP" goto SFC_VERIFY
if "!DS!"=="0" (
 >>"!OUT!" echo DISM ScanHealth: Programm erfolgreich, Statusmeldung prfen.
) else (
 >>"!OUT!" echo DISM ScanHealth: Code !DS! - Prfung fehlgeschlagen/unklar.
)
call :DISM_TEXT "!LOGDIR!\30_DISM_ScanHealth.txt" "DISM ScanHealth"
:SFC_VERIFY
if /I "!SV!"=="SKIP" goto DISM_RESTORE
if "!SV!"=="0" (
 >>"!OUT!" echo SFC VerifyOnly: Code 0; die Textausgabe entscheidet ber Befunde.
) else (
 >>"!OUT!" echo SFC VerifyOnly: Code !SV! - Befund/Fehler im Text prfen.
)
call :SFC_TEXT "!LOGDIR!\40_SFC_VerifyOnly.txt" "SFC VerifyOnly"
:DISM_RESTORE
if /I "!DR!"=="SKIP" goto SFC_REPAIR
if "!DR!"=="0" (
 >>"!OUT!" echo DISM RestoreHealth: Code 0 - laut Programm erfolgreich.
 >>"!OUT!" echo   Empfehlung: SFC laufen lassen und bei Bedarf erneut verifizieren.
) else (
 >>"!OUT!" echo DISM RestoreHealth: Code !DR! - nicht abgeschlossen/fehlgeschlagen.
 >>"!OUT!" echo   Empfehlung: passende Quelle prfen, dann gezielt wiederholen.
)
:SFC_REPAIR
if /I "!SR!"=="SKIP" goto FINISH
if "!SR!"=="0" (
 >>"!OUT!" echo SFC Scannow: Code 0; Ergebnistext auf Restsch„den prfen.
) else (
 >>"!OUT!" echo SFC Scannow: Code !SR! - Ausgabetext und Offline-Bootpfad prfen.
)
call :SFC_TEXT "!LOGDIR!\30_SFC_Scannow.txt" "SFC Scannow"
:FINISH
>>"!OUT!" echo.
>>"!OUT!" echo NŽCHSTE SCHRITTE:
>>"!OUT!" echo - Zuerst Original-Logs ansehen; keine blinde Reparaturkette.
>>"!OUT!" echo - Hardwarefehler/I/O: zuerst Sicherung, nicht CHKDSK /r.
>>"!OUT!" echo - DISM-Sch„den: Quelle passend zu Windows-Build suchen.
>>"!OUT!" echo - Systemdateien: nach DISM SFC erneut prfen.
>>"!OUT!" echo - Bootprobleme: im Boot-Men die Ziel-BCD gezielt untersuchen.
>>"!OUT!" echo - Erfolgreiche Prfungen garantieren KEIN startf„higes Windows.
echo.
echo =================== AUSWERTUNG ================================
type "!OUT!"
echo.
echo Bericht: "!OUT!"
exit /b 0

:DISM_TEXT
if not exist "%~1" exit /b 0
if not exist "%SystemRoot%\System32\findstr.exe" (
 >>"!OUT!" echo   %~2: Textsuche in diesem WinPE nicht verfgbar.
 >>"!OUT!" echo   Empfehlung: Originalprotokoll und Exitcode manuell lesen.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"component store is repairable" /C:"Komponentenspeicher ist reparierbar" /C:"Komponentenspeicher kann repariert werden" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Text weist auf reparierbaren Komponentenschaden hin.
 >>"!OUT!" echo   Empfehlung: DISM RestoreHealth, ggf. mit passender Quelle.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"component store is not repairable" /C:"Komponentenspeicher kann nicht repariert werden" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Text weist auf nicht reparablen Zustand hin!
 >>"!OUT!" echo   Empfehlung: Daten sichern; weitere Reparatur planen.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"No component store corruption detected" /C:"Keine Besch„digung des Komponentenspeichers erkannt" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Text meldet keinen erkannten Komponentenschaden.
 exit /b 0
)
>>"!OUT!" echo   %~2: Keine eindeutig zuordenbare Statusmeldung gefunden.
exit /b 0
:SFC_TEXT
if not exist "%~1" exit /b 0
if not exist "%SystemRoot%\System32\findstr.exe" (
 >>"!OUT!" echo   %~2: Textsuche in diesem WinPE nicht verfgbar.
 >>"!OUT!" echo   Empfehlung: Originalprotokoll und Exitcode manuell lesen.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"did not find any integrity violations" /C:"hat keine Integrit„tsverletzungen gefunden" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Laut Text keine Integrit„tsverletzungen erkannt.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"was unable to fix some of them" /C:"konnten nicht repariert werden" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Laut Text konnten Systemdateien NICHT vollst„ndig repariert werden.
 >>"!OUT!" echo   Empfehlung: DISM-Quelle, Offline-Bootpfad und CBS-Log prfen.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"successfully repaired them" /C:"erfolgreich repariert" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Laut Text wurden Systemdateien repariert.
 >>"!OUT!" echo   Empfehlung: SFC erneut verifizieren und Original-Logs lesen.
 exit /b 0
)
"%SystemRoot%\System32\findstr.exe" /I /C:"found integrity violations" /C:"found corrupt files" /C:"hat Integrit„tsverletzungen gefunden" /C:"hat besch„digte Dateien gefunden" "%~1" >nul 2>&1
if not errorlevel 1 (
 >>"!OUT!" echo   %~2: Laut Text sind besch„digte Systemdateien vorhanden.
 >>"!OUT!" echo   Empfehlung: DISM-Status, dann SFC-Reparatur prfen.
 exit /b 0
)
>>"!OUT!" echo   %~2: Keine eindeutig zuordenbare Statusmeldung gefunden.
exit /b 0
