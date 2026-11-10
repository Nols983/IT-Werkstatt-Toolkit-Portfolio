@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem IT-WERKSTATT TOOLKIT v2.4.2 - FEHLERANALYSE
rem Nur Diagnose in Windows PE/RE; keine automatischen Reparaturen.
rem Dateicodierung CP850, Zeilenenden CRLF.
chcp 850 >nul 2>&1
set "WIN="
set "CASE="
set "CASE_NAME="
set "LOGDIR="
set "NOLS_SAVE_LOGS=N"
set "M=%~dp0"

:SELECT_CASE
cls
echo ================================================================
echo                 IT-WERKSTATT TOOLKIT - FEHLERANALYSE
echo ================================================================
echo.
echo   [1] Windows startet nicht
echo   [2] Bluescreen oder Absturz
echo   [3] Windows ist langsam
echo   [4] Windows-Update schlÑgt fehl
echo   [5] Windows friert ein
echo   [6] Netzwerk oder Internet funktioniert nicht
echo   [7] Unbekanntes Problem
echo.
echo   [0] ZurÅck zum HauptmenÅ
echo ================================================================
set "CASE="
set "CASE_NAME="
set /p "CASE=Fehlerbild wÑhlen: "
if "!CASE!"=="0" exit /b 0
if "!CASE!"=="1" set "CASE_NAME=Windows startet nicht"
if "!CASE!"=="2" set "CASE_NAME=Bluescreen oder Absturz"
if "!CASE!"=="3" set "CASE_NAME=Windows ist langsam"
if "!CASE!"=="4" set "CASE_NAME=Windows-Update schlÑgt fehl"
if "!CASE!"=="5" set "CASE_NAME=Windows friert ein"
if "!CASE!"=="6" set "CASE_NAME=Netzwerk oder Internet"
if "!CASE!"=="7" set "CASE_NAME=Unbekanntes Problem"
if not defined CASE_NAME goto SELECT_CASE

cls
echo ================================================================
echo   FEHLERANALYSE: !CASE_NAME!
echo ================================================================
echo.
echo Es werden keine Reparaturen oder Bootloader-énderungen gestartet.
echo Bei ungewîhnlichen GerÑuschen oder I/O-Fehlern zuerst Daten sichern.
echo Die Laufwerksbuchstaben in WinPE kînnen abweichen.
echo.
set "WIN="
call "%M%ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 (
  echo ABBRUCH: Keine Windows-Installation gewÑhlt.
  echo.
  pause
  exit /b 1
)
set "LOG_ANSWER="
echo.
set /p "LOG_ANSWER=Sollen Logs auf dem Toolkit-Laufwerk erstellt werden? [Y/N, Enter=N]: "
if /I "!LOG_ANSWER!"=="Y" set "NOLS_SAVE_LOGS=Y"
if /I "!NOLS_SAVE_LOGS!"=="Y" (
  call "%M%MakeLogDir.cmd" LOGDIR FEHLERANALYSE
  if errorlevel 1 (
    echo ABBRUCH: Logordner nicht beschreibbar.
    exit /b 1
  )
  >"!LOGDIR!\00_Fall.txt" echo IT-WERKSTATT TOOLKIT v2.4.2 - FEHLERANALYSE
  >>"!LOGDIR!\00_Fall.txt" echo Fehlerbild: !CASE_NAME!
  >>"!LOGDIR!\00_Fall.txt" echo Windows: !WIN!:\Windows
  echo Protokollordner: "!LOGDIR!"
) else (
  echo Keine dauerhaften Toolkit-Diagnoselogs ausgewÑhlt.
)
call :BASIS
call :SHOW_ADVICE
call :ANALYSE
echo.
pause

:CASE_MENU
cls
echo ================================================================
echo                   FEHLERANALYSE - IT-WERKSTATT TOOLKIT
echo ================================================================
echo Fehlerbild: !CASE_NAME!
echo Ziel: !WIN!:\Windows
echo.
echo   EINZELPRUEFUNGEN - NUR LESEN
echo   --------------------------------------------------------------
echo   [1] Schnellpruefung wiederholen
echo   [2] Absturzdateien / Minidumps suchen
echo   [3] Offline-Ereignisse auslesen
echo   [4] CHKDSK ohne /f
echo   [5] DISM CheckHealth
echo   [6] SFC verifyonly
echo   [7] Windows-Update-Informationen
echo   [8] Netzwerk dieser WinPE-Sitzung
echo   [9] Empfohlene naechste Schritte
echo.
echo   WEITERE ANALYSEN
echo   --------------------------------------------------------------
echo   [D] Datentraegeranalyse
echo   [B] BSOD- und Treiberanalyse
echo   [T] Zeitpruefung
echo.
echo   BERICHTE
echo   --------------------------------------------------------------
echo   [A] Analysebericht aktualisieren
echo   [W] Werkstattbericht anzeigen
echo.
echo   [0] Fehleranalyse beenden
echo ================================================================
set "ACTION="
set /p "ACTION=Auswahl: "
if "!ACTION!"=="0" goto END
set "KNOWN=N"
for %%V in (1 2 3 4 5 6 7 8 9 A B D T W) do if /I "!ACTION!"=="%%V" set "KNOWN=Y"
if "!KNOWN!"=="N" (
 echo Ungueltige Auswahl.
 pause
 goto CASE_MENU
)
if "!ACTION!"=="1" call :BASIS
if "!ACTION!"=="2" call :DUMPS
if "!ACTION!"=="3" call :EVENTS
if "!ACTION!"=="4" call :CHKDSK_CHECK
if "!ACTION!"=="5" call :DISM_CHECK
if "!ACTION!"=="6" call :SFC_CHECK
if "!ACTION!"=="7" call :UPDATE_INFO
if "!ACTION!"=="8" call :NETWORK
if "!ACTION!"=="9" call :SHOW_ADVICE
if /I "!ACTION!"=="A" call :ANALYSE
if /I "!ACTION!"=="W" call :SHOW_WORKSHOP
if /I "!ACTION!"=="D" call "%M%SpeicherAnalyse.cmd" "!WIN!" "!LOGDIR!" "IN_CASE"
if /I "!ACTION!"=="B" call "%M%TreiberBSOD.cmd" "!WIN!" "!LOGDIR!" "IN_CASE"
if /I "!ACTION!"=="T" call "%M%TimeCheck.cmd"
echo.
pause
goto CASE_MENU

:ANALYSE
echo.
call "%M%AnalyseBericht.cmd" "!WIN!" "!CASE!" "!LOGDIR!"
exit /b 0

:SHOW_WORKSHOP
echo.
if defined LOGDIR if exist "!LOGDIR!\97_Werkstattbericht.txt" (
 type "!LOGDIR!\97_Werkstattbericht.txt"
 exit /b 0
)
echo Kein gespeicherter Werkstattbericht vorhanden.
echo Eine neue Auswertung kann ihn anzeigen.
echo.
set "GO="
set /p "GO=Auswertung jetzt starten? [Y/N, Enter=N]: "
if /I "!GO!"=="Y" call :ANALYSE
exit /b 0

:BASIS
echo.
echo ===================== SCHNELLPRöFUNG ==========================
echo Windows unter !WIN!:\Windows ist erreichbar.
set "REPORT="
if defined LOGDIR set "REPORT=!LOGDIR!\01_Schnellpruefung.txt"
if defined REPORT >"!REPORT!" echo IT-WERKSTATT - Schnellpruefung: !CASE_NAME!
call :CHECKFILE "!WIN!:\Windows\System32\winload.efi" "UEFI-Windows-Bootloader"
call :CHECKFILE "!WIN!:\Windows\System32\Config\SYSTEM" "Offline-System-Registry"
call :CHECKFILE "!WIN!:\Windows\System32\Config\BCD-Template" "BCD-Vorlage"
if "!CASE!"=="1" (
  echo HINWEIS: EFI-/BCD-PrÅfung erfolgt gesondert unter BOOT-WERKZEUGE.
  if defined REPORT >>"!REPORT!" echo NÑchster Schritt: HauptmenÅ [6] BOOT-WERKZEUGE.
)
if "!CASE!"=="2" call :DUMPS
if "!CASE!"=="5" call :DUMPS
if "!CASE!"=="4" call :UPDATE_HINT
if "!CASE!"=="6" (
 echo HINWEIS: Das installierte Windows lÑuft hier nicht. PE-Netzwerktest
 echo prÅft die aktuelle Recovery-Umgebung und nicht ihre Treiber/Firewall.
)
echo.
echo Eine vorhandene Datei ist KEIN Beweis fÅr ein gesundes Windows.
exit /b 0

:CHECKFILE
if exist "%~1" (
 echo [VORHANDEN] %~2
 if defined REPORT >>"!REPORT!" echo VORHANDEN: %~1
) else (
 echo [FEHLT / NICHT LESBAR] %~2
 if defined REPORT >>"!REPORT!" echo FEHLT: %~1
)
exit /b 0

:DUMPS
echo.
echo ====================== ABSTURZDATEIEN =========================
if defined LOGDIR >"!LOGDIR!\10_Dumps.txt" echo IT-WERKSTATT - Absturzdateien, keine Analyse des Dump-Inhalts.
if exist "!WIN!:\Windows\Minidump\*.dmp" (
 echo Minidumps vorhanden: !WIN!:\Windows\Minidump\
 dir /a:-d /o:-d "!WIN!:\Windows\Minidump\*.dmp"
 if defined LOGDIR dir /a:-d /o:-d "!WIN!:\Windows\Minidump\*.dmp" >>"!LOGDIR!\10_Dumps.txt" 2>&1
) else (
 echo Keine Minidumps gefunden oder Ordner nicht lesbar.
 if defined LOGDIR >>"!LOGDIR!\10_Dumps.txt" echo Keine Minidumps gefunden.
)
if exist "!WIN!:\Windows\MEMORY.DMP" (
 echo [VORHANDEN] !WIN!:\Windows\MEMORY.DMP
 dir /a:-d "!WIN!:\Windows\MEMORY.DMP"
 if defined LOGDIR dir /a:-d "!WIN!:\Windows\MEMORY.DMP" >>"!LOGDIR!\10_Dumps.txt" 2>&1
) else (
 echo Keine MEMORY.DMP gefunden.
 if defined LOGDIR >>"!LOGDIR!\10_Dumps.txt" echo Keine MEMORY.DMP gefunden.
)
echo HINWEIS: Eine Dumpdatei allein verrÑt noch NICHT die Fehlerursache.
echo FÅr eine echte Dumpanalyse wird spÑter ein geeigneter Debugger benîtigt.
exit /b 0

:EVENTS
echo.
echo ================== OFFLINE-EREIGNISSE =========================
set "EVENT_FILE=!WIN!:\Windows\System32\winevt\Logs\System.evtx"
if not exist "!EVENT_FILE!" (
 echo Keine lesbare System.evtx gefunden.
 exit /b 1
)
if not exist "%SystemRoot%\System32\wevtutil.exe" (
 echo wevtutil.exe fehlt in dieser WinPE-Umgebung.
 echo Originaldatei: !EVENT_FILE!
 exit /b 1
)
echo Neueste EintrÑge zu Kernel-Power 41, BugCheck 1001 und 6008.
echo Ereignis 41/6008 belegt nur einen unerwarteten Shutdown,
echo nicht dessen Ursache. Ereignis 1001 kann mehrere Quellen haben.
set "EQUERY=*[System[(EventID=41 or EventID=1001 or EventID=6008)]]"
if defined LOGDIR (
 "%SystemRoot%\System32\wevtutil.exe" qe "!EVENT_FILE!" /lf:true /rd:true /c:12 /f:text "/q:!EQUERY!" >"!LOGDIR!\20_Systemevents.txt" 2>&1
 set "RC=!errorlevel!"
 type "!LOGDIR!\20_Systemevents.txt"
) else (
 "%SystemRoot%\System32\wevtutil.exe" qe "!EVENT_FILE!" /lf:true /rd:true /c:12 /f:text "/q:!EQUERY!"
 set "RC=!errorlevel!"
)
if not "!RC!"=="0" echo HINWEIS: Ereignisabfrage fehlgeschlagen oder keine passenden EintrÑge.
exit /b 0

:CHKDSK_CHECK
echo.
echo CHKDSK prÅft !WIN!: ohne /f oder /r.
echo Auch reine Lesetests kînnen physisch defekte Laufwerke belasten.
set "GO="
set /p "GO=PrÅfung starten? [Y/N]: "
if /I not "!GO!"=="Y" exit /b 0
if defined LOGDIR (
 echo CHKDSK lÑuft; Ausgabe erscheint anschlie·end.
 "%SystemRoot%\System32\chkdsk.exe" !WIN!: >"!LOGDIR!\30_CHKDSK.txt" 2>&1
 set "RC=!errorlevel!"
 type "!LOGDIR!\30_CHKDSK.txt"
) else (
 "%SystemRoot%\System32\chkdsk.exe" !WIN!:
 set "RC=!errorlevel!"
)
echo CHKDSK-RÅckgabecode: !RC! - Originalausgabe beachten.
exit /b 0

:DISM_CHECK
echo.
echo DISM /Image:!WIN!:\ /Cleanup-Image /CheckHealth
echo Keine Reparatur; Windows-Komponentenspeicher wird abgefragt.
set "GO="
set /p "GO=PrÅfung starten? [Y/N]: "
if /I not "!GO!"=="Y" exit /b 0
if not exist "%SystemRoot%\System32\dism.exe" (
 echo DISM nicht verfÅgbar.
 exit /b 1
)
if defined LOGDIR (
 "%SystemRoot%\System32\dism.exe" /Image:!WIN!:\ /Cleanup-Image /CheckHealth "/LogPath:!LOGDIR!\31_DISM_detail.log" >"!LOGDIR!\31_DISM.txt" 2>&1
 set "RC=!errorlevel!"
 type "!LOGDIR!\31_DISM.txt"
) else (
 "%SystemRoot%\System32\dism.exe" /Image:!WIN!:\ /Cleanup-Image /CheckHealth
 set "RC=!errorlevel!"
)
echo DISM-RÅckgabecode: !RC! - Originalausgabe beachten.
exit /b 0

:SFC_CHECK
echo.
echo SFC /verifyonly - keine Reparatur.
echo Vorgabe: Das Windows-Laufwerk dient zugleich als /offbootdir.
echo Bei abweichendem Bootvolume bitte das bisherige SFC-Einzelmodul
 echo mit gesonderter Bootpfadauswahl verwenden.
set "GO="
set /p "GO=PrÅfung starten? [Y/N]: "
if /I not "!GO!"=="Y" exit /b 0
if not exist "%SystemRoot%\System32\sfc.exe" (
 echo SFC nicht verfÅgbar.
 exit /b 1
)
if defined LOGDIR (
 "%SystemRoot%\System32\sfc.exe" /verifyonly /offbootdir=!WIN!:\ /offwindir=!WIN!:\Windows "/offlogfile=!LOGDIR!\32_SFC_detail.log" >"!LOGDIR!\32_SFC.txt" 2>&1
 set "RC=!errorlevel!"
 type "!LOGDIR!\32_SFC.txt"
) else (
 "%SystemRoot%\System32\sfc.exe" /verifyonly /offbootdir=!WIN!:\ /offwindir=!WIN!:\Windows
 set "RC=!errorlevel!"
)
echo SFC-RÅckgabecode: !RC! - Originalausgabe beachten.
exit /b 0

:UPDATE_HINT
echo.
echo ====================== UPDATE-STATUS =========================
if exist "!WIN!:\Windows\WinSxS\pending.xml" (
 echo [HINWEIS] WinSxS\pending.xml ist vorhanden.
 echo Das kann zu ausstehenden Komponentenaktionen passen, ist alleine
 echo aber KEIN Beweis fÅr einen festhÑngenden Updatevorgang.
) else (
 echo Keine pending.xml gefunden. Das schlie·t Updateprobleme nicht aus.
)
exit /b 0

:UPDATE_INFO
call :UPDATE_HINT
set "UPD_FILE="
rem Offline-Log hat im Windows-Dateinamen ein Prozentzeichen; Wildcard ist robuster.
for %%F in ("!WIN!:\Windows\System32\winevt\Logs\Microsoft-Windows-WindowsUpdateClient*Operational.evtx") do if exist "%%~fF" set "UPD_FILE=%%~fF"
if defined UPD_FILE (
 echo.
 echo WindowsUpdateClient-Ereignisdatei vorhanden.
 if exist "%SystemRoot%\System32\wevtutil.exe" (
  echo Zeige die letzten 12 UpdateClient-EintrÑge.
  if defined LOGDIR (
   "%SystemRoot%\System32\wevtutil.exe" qe "!UPD_FILE!" /lf:true /rd:true /c:12 /f:text >"!LOGDIR!\40_UpdateEvents.txt" 2>&1
   type "!LOGDIR!\40_UpdateEvents.txt"
  ) else (
   "%SystemRoot%\System32\wevtutil.exe" qe "!UPD_FILE!" /lf:true /rd:true /c:12 /f:text
  )
 ) else (
  echo wevtutil fehlt; keine automatische Ereignis-Auswertung.
 )
) else (
 echo WindowsUpdateClient-Operational.evtx nicht gefunden.
)
echo.
echo ZusÑtzliche DISM-Paketliste kann lang sein.
set "GO="
set /p "GO=Installierte/Ausstehende Pakete auflisten? [Y/N]: "
if /I not "!GO!"=="Y" exit /b 0
if not exist "%SystemRoot%\System32\dism.exe" (
 echo DISM nicht verfÅgbar.
 exit /b 1
)
if defined LOGDIR (
 echo DISM-PaketÅbersicht lÑuft, Ausgabe folgt.
 "%SystemRoot%\System32\dism.exe" /Image:!WIN!:\ /Get-Packages /Format:Table "/LogPath:!LOGDIR!\41_Pakete_detail.log" >"!LOGDIR!\41_Pakete.txt" 2>&1
 type "!LOGDIR!\41_Pakete.txt"
) else (
 "%SystemRoot%\System32\dism.exe" /Image:!WIN!:\ /Get-Packages /Format:Table
)
exit /b 0

:NETWORK
echo.
echo ======================== NETZWERK ============================
echo ACHTUNG: Dies prÅft nur das aktuell gestartete WinPE-Netzwerk,
echo nicht die installierten Windows-Treiber oder Firewallregeln.
if not exist "%SystemRoot%\System32\ipconfig.exe" (
 echo ipconfig.exe fehlt in WinPE.
 exit /b 1
)
if defined LOGDIR (
 "%SystemRoot%\System32\ipconfig.exe" /all >"!LOGDIR!\50_Netzwerk_PE.txt" 2>&1
 type "!LOGDIR!\50_Netzwerk_PE.txt"
) else (
 "%SystemRoot%\System32\ipconfig.exe" /all
)
exit /b 0

:SHOW_ADVICE
if defined LOGDIR (
 call :ADVICE >"!LOGDIR!\90_Empfehlung.txt"
 type "!LOGDIR!\90_Empfehlung.txt"
) else (
 call :ADVICE
)
exit /b 0

:ADVICE
echo.
echo ===================== NéCHSTE SCHRITTE ======================
if "!CASE!"=="1" (
 echo 1. Firmwaremodus und EFI/BCD unter HauptmenÅ [6] prÅfen.
 echo 2. CHKDSK ohne /f, DISM und SFC bei passenden Symptomen prÅfen.
 echo 3. BCDBoot nur mit korrektem ESP-Ziel und vorheriger BCD-Sicherung.
)
if "!CASE!"=="2" (
 echo 1. Minidumps/MEMORY.DMP mit Debugger auswerten, nicht nur zÑhlen.
 echo 2. Ereignisse 41/1001/6008 als Zeitachse, nicht als Ursache nutzen.
 echo 3. Treiber, RAM und Speichermedien systematisch testen.
)
if "!CASE!"=="3" (
 echo 1. DatentrÑger-SMART mit geeigneter Live-Umgebung prÅfen.
 echo 2. CHKDSK und Ereignisse nur bei vertretbarem Laufwerkszustand.
 echo 3. Autostart, Dienste und Ressourcenauslastung im Windows-Desktop prÅfen.
)
if "!CASE!"=="4" (
 echo 1. DISM CheckHealth und Update-Ereignisse prÅfen.
 echo 2. Paketstatus abgleichen; passende Windows-Quelle vorhalten.
 echo 3. DISM /RestoreHealth nur gezielt und bei gesicherter Datenlage.
)
if "!CASE!"=="5" (
 echo 1. Kernel-Power 41 beweist keine Ursache: Netzteil, RAM, SSD testen.
 echo 2. Absturzdateien und Offline-Systemereignisse prÅfen.
 echo 3. Bei I/O-Fehlern keine intensiven Scans vor der Datensicherung.
)
if "!CASE!"=="6" (
 echo 1. ipconfig im WinPE ist kein Nachweis fÅr das installierte Windows.
 echo 2. Im laufenden Windows Adapter, DHCP, DNS und Treiber prÅfen.
 echo 3. Netzwerk-Firmware und ggf. Protokolle des Zielsystems prÅfen.
)
if "!CASE!"=="7" (
 echo 1. Fehlerbild, Zeitpunkt und zuletzt geÑnderte Komponenten notieren.
 echo 2. Dateisystem, Systemereignisse, Dumps und Bootstatus prÅfen.
 echo 3. Erst dann eine passende Reparatur auswÑhlen.
)
echo.
echo Reparaturen sind absichtlich NICHT in der Fehleranalyse enthalten.
echo Nutze dafÅr die bestehenden HauptmenÅs [2], [4] oder [6].
exit /b 0

:END
echo.
if defined LOGDIR (
 echo Die Dateien dieses Falles liegen gesammelt unter:
 echo "!LOGDIR!"
) else (
 echo Keine dauerhaften Toolkit-Logs fÅr diesen Fall erstellt.
)
exit /b 0
