@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem v2.4.2: NTFS-55/140 separat; keine Zielsystem-Reparatur.
chcp 850 >nul 2>&1
set "M=%~dp0"
set "WIN=%~1"
set "OUT="
set "KEEP=N"
set "FROM_CASE=N"
set "TEMP_CREATED=N"
set "V_NTFS55_ALL=?"
set "V_NTFS140_ALL=?"
if /I "%~3"=="IN_CASE" set "FROM_CASE=Y"
if not defined WIN call "%M%ChooseDrive.cmd" WIN WINDOWS
if not defined WIN exit /b 1
set "VALID=N"
for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if /I "!WIN!"=="%%L" set "VALID=Y"
if "!VALID!"=="N" (
 echo ABBRUCH: Ungueltiger Laufwerksbuchstabe.
 exit /b 1
)
if not exist "!WIN!:\Windows\System32\Config\SYSTEM" (
 echo ABBRUCH: Windows-Ziel nicht erreichbar.
 exit /b 1
)
set "EVT=!WIN!:\Windows\System32\winevt\Logs\System.evtx"
if "!FROM_CASE!"=="Y" (
 if not "%~2"=="" (
  set "OUT=%~2\v23_Speicher"
  set "KEEP=Y"
 )
) else (
 echo.
 set "ANSWER="
 set /p "ANSWER=Sollen Logs auf dem Toolkit-Laufwerk erstellt werden? [Y/N, Enter=N]: "
 if /I "!ANSWER!"=="Y" (
  set "NOLS_SAVE_LOGS=Y"
  call "%M%MakeLogDir.cmd" OUT SPEICHER
  if errorlevel 1 exit /b 1
  set "KEEP=Y"
 )
)
if "!KEEP!"=="N" (
 if not defined TEMP set "TEMP=%SystemRoot%\Temp"
 set "OUT=!TEMP!\NOLS_V23_!RANDOM!_!RANDOM!"
 set "TEMP_CREATED=Y"
)
if exist "!OUT!\." (
 if "!TEMP_CREATED!"=="Y" (
  echo ABBRUCH: Temp-Ordner schon vorhanden.
  exit /b 1
 )
) else (
 md "!OUT!" >nul 2>&1
 if errorlevel 1 (
  echo ABBRUCH: Arbeitsverzeichnis nicht beschreibbar.
  exit /b 1
 )
)
md "!OUT!\EventXML" >nul 2>&1
if not exist "!OUT!\EventXML\." (
 echo ABBRUCH: EventXML-Ordner fehlt.
 exit /b 1
)
cls
echo ================================================================
echo          IT-WERKSTATT TOOLKIT - DATENTRAEGER / I-O
echo ================================================================
echo Ziel: !WIN!:\Windows
echo Nur Diagnose. Eventzeiten in XML sind UTC.
echo Ein gemeinsames Zeitfenster beweist KEINE gemeinsame Ursache.
echo Bei I/O-Fehlern oder auffaelligen Geraeuschen zuerst Daten sichern.
echo.
call :DISKPART_OVERVIEW
if not exist "!EVT!" (
 echo [OFFEN] Offline-System.evtx fehlt oder ist nicht lesbar.
 >"!OUT!\00_Hinweise.txt" echo [OFFEN] Offline-System.evtx fehlt.
 goto SUMMARIZE
)
if not exist "%SystemRoot%\System32\wevtutil.exe" (
 echo [OFFEN] wevtutil fehlt in WinPE.
 >"!OUT!\00_Hinweise.txt" echo [OFFEN] wevtutil fehlt in WinPE.
 goto SUMMARIZE
)
set "B_DISK=(Provider[@Name='disk'] or Provider[@Name='Microsoft-Windows-Disk']) and (EventID=7 or EventID=11 or EventID=51 or EventID=153 or EventID=157)"
set "B_STOR=(Provider[@Name='storahci'] or Provider[@Name='stornvme'] or Provider[@Name='storport'] or Provider[@Name='iaStorA'] or Provider[@Name='iaStorAC'] or Provider[@Name='iaStorAVC']) and EventID=129"
set "B_NTFS=(Provider[@Name='Ntfs'] or Provider[@Name='Microsoft-Windows-Ntfs']) and (EventID=55 or EventID=98 or EventID=140)"
set "B_WHEA=Provider[@Name='Microsoft-Windows-WHEA-Logger'] and (EventID=17 or EventID=18 or EventID=19)"
call :GROUP "DISK" "!B_DISK!"
call :GROUP "STOR" "!B_STOR!"
call :GROUP "NTFS" "!B_NTFS!"
call :GROUP "WHEA" "!B_WHEA!"
rem Zusatzauswertung vermeidet falschen Schluss aus NTFS-98-Infomeldungen.
set "B_NTFS55=(Provider[@Name='Ntfs'] or Provider[@Name='Microsoft-Windows-Ntfs']) and EventID=55"
set "B_NTFS140=(Provider[@Name='Ntfs'] or Provider[@Name='Microsoft-Windows-Ntfs']) and EventID=140"
set "Q_NTFS55=*[System[!B_NTFS55!]]"
set "Q_NTFS140=*[System[!B_NTFS140!]]"
call :FETCH "NTFS55" "ALL" "!Q_NTFS55!" 1
call :FETCH "NTFS140" "ALL" "!Q_NTFS140!" 1
:SUMMARIZE
call :REPORT >"!OUT!\90_Speicherbericht.txt"
type "!OUT!\90_Speicherbericht.txt"
echo.
if "!KEEP!"=="Y" (
 echo Protokolle: "!OUT!"
 echo Exakte Zeitkorrelation am Linux-Laptop:
 echo python3 Recovery/Analyse/offline_analyse.py "!OUT!" --mode storage
) else (
 rd /s /q "!OUT!" >nul 2>&1
 if exist "!OUT!\." echo HINWEIS: Temporare Dateien konnten nicht entfernt werden.
)
exit /b 0

:DISKPART_OVERVIEW
if not exist "%SystemRoot%\System32\diskpart.exe" (
 echo [OFFEN] diskpart nicht vorhanden.
 exit /b 0
)
set "DPS=!OUT!\list_disks_volumes.dps"
>"!DPS!" echo list disk
>>"!DPS!" echo list volume
"%SystemRoot%\System32\diskpart.exe" /s "!DPS!" >"!OUT!\01_DiskPart.txt" 2>&1
type "!OUT!\01_DiskPart.txt"
del /q "!DPS!" >nul 2>&1
echo.
echo Fuer Zuordnung von Ereignissen zu physischer Hardware ist
 echo die Datentraeger- und Volume-Liste nur ein Anhaltspunkt.
echo.
set "DNUM="
set /p "DNUM=Optional: Datentraeger-Nr. fuer detail disk [Enter=ueberspringen]: "
if not defined DNUM exit /b 0
set "DOK=N"
for /L %%N in (0,1,127) do if "!DNUM!"=="%%N" set "DOK=Y"
if "!DOK!"=="N" (
 echo Ungueltige Nummer, uebersprungen.
 exit /b 0
)
set "DPS=!OUT!\detail_disk.dps"
>"!DPS!" echo select disk !DNUM!
>>"!DPS!" echo detail disk
"%SystemRoot%\System32\diskpart.exe" /s "!DPS!" >"!OUT!\02_DiskDetail.txt" 2>&1
type "!OUT!\02_DiskDetail.txt"
del /q "!DPS!" >nul 2>&1
exit /b 0

:GROUP
set "G_NAME=%~1"
set "G_FILTER=%~2"
set "G_ALL=*[System[!G_FILTER!]]"
set "G_7=*[System[!G_FILTER! and TimeCreated[timediff(@SystemTime) <= 604800000]]]"
set "G_30=*[System[!G_FILTER! and TimeCreated[timediff(@SystemTime) <= 2592000000]]]"
call :FETCH "!G_NAME!" "ALL" "!G_ALL!" 80
call :FETCH "!G_NAME!" "7D" "!G_7!" 1
call :FETCH "!G_NAME!" "30D" "!G_30!" 1
exit /b 0

:FETCH
set "TAG=%~1_%~2"
set "F=!OUT!\EventXML\!TAG!.xml"
set "ERR=!OUT!\EventXML\!TAG!.err.txt"
"%SystemRoot%\System32\wevtutil.exe" qe "!EVT!" /lf:true /rd:true /f:xml /uni:false /e:Events /c:%~4 "/q:%~3" 1>"!F!" 2>"!ERR!"
if errorlevel 1 (
 set "V_!TAG!=?"
 echo [OFFEN] !TAG!: Abfrage fehlgeschlagen; siehe !TAG!.err.txt
 exit /b 0
)
for %%Z in ("!F!") do set "FSIZE=%%~zZ"
if !FSIZE! LSS 21 (
 set "V_!TAG!=?"
) else if !FSIZE! EQU 21 (
 set "V_!TAG!=N"
) else (
 set "V_!TAG!=Y"
)
exit /b 0

:REPORT
echo ================================================================
echo               IT-WERKSTATT DATENTRAEGERANALYSE
echo ================================================================
echo Windows: !WIN!:\Windows
echo Quelle: Offline-System.evtx, falls erreichbar.
echo.
echo KATEGORIE           Treffer in       Treffer in
 echo                     letzten 7 Tagen  letzten 30 Tagen
echo ---------------------------------------------------------------
call :LINE DISK "Datentraeger-I/O"
call :LINE STOR "Controller-Reset"
call :LINE NTFS "NTFS-Ereignisse"
call :LINE WHEA "WHEA-Hardware"
echo.
echo NTFS-55-Fehlerhinweis vorhanden: !V_NTFS55_ALL!
echo NTFS-140-Hinweis vorhanden: !V_NTFS140_ALL!
echo Info: NTFS-ID 98 kann eine regulaere Volumenpruefung melden.
echo Hinweis: Y bedeutet vorhanden; ? bedeutet nicht auswertbar.
echo.
echo Y = mindestens ein Treffer im Zeitfenster; N = kein Treffer
 echo in begrenzter Abfrage; ? = nicht auswertbar.
echo Umfangreichere Originalereignisse: EventXML/*_ALL.xml
 echo Die ALL-Abfragen sind auf 80 neueste Treffer je Gruppe begrenzt.
echo.
if "!V_DISK_7D!"=="Y" if "!V_STOR_7D!"=="Y" echo [HINWEIS] Disk- und Controllerereignisse in derselben 7-Tage-Periode.
if "!V_DISK_30D!"=="Y" if "!V_NTFS_30D!"=="Y" echo [HINWEIS] Disk- und NTFS-Ereignisse im selben 30-Tage-Zeitraum.
echo Das ist KEIN Beweis fuer Ereignisse im selben Minutenfenster.
echo Exakte 5-Minuten-Korrelation: Linux-Auswerter im Paket.
echo Datentraegernummern aus DiskPart sind nicht automatisch mit
 echo Event-Device-IDs verknuepft. Keine SSD/HDD-Schuldzuweisung.
echo Empfehlungen: SMART auswerten, Anschluss/Controller pruefen;
 echo bei starkem Fehlerverdacht zuerst Image/Datensicherung.
echo Keine Schreibreparaturen ausgefuehrt.
echo ================================================================
exit /b 0

:LINE
set "T7=!V_%~1_7D!"
set "T30=!V_%~1_30D!"
if not defined T7 set "T7=?"
if not defined T30 set "T30=?"
echo %~2: !T7! / !T30!
exit /b 0
