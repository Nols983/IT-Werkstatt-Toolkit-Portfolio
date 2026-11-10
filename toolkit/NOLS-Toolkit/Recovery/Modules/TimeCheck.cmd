@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem NOLS v2.2: manuelle ZeitprÅfung fÅr Windows PE / RE.
rem Kein Zugriff auf verlÑssliche Online-Zeit garantiert. Keine stille énderung.
chcp 850 >nul 2>&1
:CHECK
cls
echo ================================================================
echo               IT-WERKSTATT TOOLKIT - ZEITPRUEFUNG
echo ================================================================
echo.
echo Aktuelle Datum-/Uhrzeitanzeige dieser WinPE-Sitzung:
echo.
date /t
time /t
echo.
if exist "%SystemRoot%\System32\tzutil.exe" (
  echo Zeitzone:
  "%SystemRoot%\System32\tzutil.exe" /g
) else (
  echo Zeitzone: tzutil in WinPE nicht verfÅgbar.
)
echo.
echo WICHTIG: Ohne verlÑssliche Zeitquelle ist diese Anzeige
 echo keine automatische BestÑtigung der korrekten Uhrzeit.
echo Ereignisse in EventXML nutzen UTC; Dateizeitstempel sind lokal.
echo.
set "REPLY="
set /p "REPLY=Sind Datum und Uhrzeit korrekt? [Y/N, Enter=N]: "
if /I "!REPLY!"=="Y" goto GOOD
:NOT_GOOD
echo.
echo Zeit ist noch NICHT bestÑtigt. Fall-Logs kînnen falsch datiert sein.
echo Nur die Uhr der laufenden WinPE-Sitzung kann korrigiert werden.
set "FIX="
set /p "FIX=Datum und Uhrzeit jetzt manuell einstellen? [Y/N, Enter=N]: "
if /I not "!FIX!"=="Y" goto UNKNOWN
echo.
echo Datum eingeben ^(Windows fragt nach dem aktuellen Datum^):
date
echo.
echo Uhrzeit eingeben ^(Windows fragt nach der aktuellen Uhrzeit^):
time
goto CHECK
:GOOD
echo [OK] Zeit wurde von dir bestÑtigt.
endlocal & set "NOLS_TIME_STATUS=BESTAETIGT"
exit /b 0
:UNKNOWN
echo [HINWEIS] Zeit nicht bestÑtigt; Zeitstempel nur unter Vorbehalt.
endlocal & set "NOLS_TIME_STATUS=NICHT_BESTAETIGT"
exit /b 0
