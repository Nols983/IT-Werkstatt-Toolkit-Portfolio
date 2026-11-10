@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 850 >nul 2>&1
rem Read-only report browser. Existing AnalyseResults for auto tasks untouched.
set "BASE=%~dp0..\Logs"
if not exist "!BASE!\" (
 echo Noch keine gespeicherten Diagnoseberichte vorhanden.
 exit /b 0
)
:CHOOSE
cls
echo ================================================================
echo                     IT-WERKSTATT BERICHTE
echo ================================================================
echo Protokollordner: "!BASE!"
echo.
dir /b /ad /o-d "!BASE!" 2>nul
echo.
echo [0] Zurueck zum Hauptmenue
echo.
set "NAME="
set /p "NAME=Ordnernamen eingeben (Enter=Zurueck): "
if not defined NAME exit /b 0
if "!NAME!"=="0" exit /b 0
rem Only simple local folder names: no separators, quotes or traversal.
set "INVALID_NAME="
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-" %%Z in ("!NAME!") do set "INVALID_NAME=Y"
if defined INVALID_NAME goto INVALID
if not "!NAME:..=!"=="!NAME!" goto INVALID
if not exist "!BASE!\!NAME!\" goto INVALID
set "DIR=!BASE!\!NAME!"
:REPORT
cls
echo ================================================================
echo                     GESPEICHERTE BERICHTE
echo ================================================================
echo Ordner: !NAME!
echo.
echo [1] Werkstattbericht      97_Werkstattbericht.txt
echo [2] Analysebericht        95_Analysebericht.txt
echo [3] Diagnose/Auto         00_Ergebnis.txt
echo [4] Empfehlungen          90_Empfehlungen.txt
echo [5] Speicheranalyse       v23_Speicher\90_Speicherbericht.txt
echo [6] BSOD / Treiber        v24_BSOD_Treiber\90_BSOD_Treiberbericht.txt
echo [7] Vorhandene Textdateien im Fallordner anzeigen
echo [0] Anderen Fall auswaehlen
echo.
set "N="
set /p "N=Auswahl: "
if "!N!"=="0" goto CHOOSE
if "!N!"=="1" set "FILE=!DIR!\97_Werkstattbericht.txt"
if "!N!"=="2" set "FILE=!DIR!\95_Analysebericht.txt"
if "!N!"=="3" set "FILE=!DIR!\00_Ergebnis.txt"
if "!N!"=="4" (
 set "FILE=!DIR!\90_Empfehlungen.txt"
 if not exist "!FILE!" set "FILE=!DIR!\90_Empfehlung.txt"
)
if "!N!"=="5" (
 set "FILE=!DIR!\v23_Speicher\90_Speicherbericht.txt"
 if not exist "!FILE!" set "FILE=!DIR!\90_Speicherbericht.txt"
)
if "!N!"=="6" (
 set "FILE=!DIR!\v24_BSOD_Treiber\90_BSOD_Treiberbericht.txt"
 if not exist "!FILE!" set "FILE=!DIR!\90_BSOD_Treiberbericht.txt"
)
if "!N!"=="7" (
  echo.
  dir /b /a:-d "!DIR!\*.txt" 2>nul
  echo.
  pause
  goto REPORT
)
if not defined FILE goto REPORT
echo.
if exist "!FILE!" (
 echo ===== !FILE! =====
 type "!FILE!"
) else (
 echo [NICHT VORHANDEN] Dieser Bericht wurde nicht erstellt.
 echo Es ist kein Fehlernachweis, wenn eine Datei fehlt.
)
set "FILE="
echo.
pause
goto REPORT
:INVALID
echo Unbekannter oder ungueltiger Fallordner.
pause
goto CHOOSE
