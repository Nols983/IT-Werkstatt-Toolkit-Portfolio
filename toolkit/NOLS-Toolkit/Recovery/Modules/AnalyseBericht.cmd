@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem NOLS v2.2 - Ereignis-Auswertung aus Offline-EVTX (NUR LESEN).
rem WinPE-kompatibel: wevtutil + CMD, ohne PowerShell/findstr/find.
rem Windows filtert selbst nach Ereignisquelle UND ID (XPath).
rem XML enthaelt keine lokalisierten Beschreibungstexte, die den
rem vorherigen for /f Parser wegen 0x00-Zeichen abbrachen.
chcp 850 >nul 2>&1
set "WIN=%~1"
set "CASE=%~2"
set "LOGDIR=%~3"
set "WORK="
set "TEMP_CREATED=N"
set "OFF_SYS=%WIN%:\Windows\System32\winevt\Logs\System.evtx"
set "OFF_UPD="
set "SYS_FOUND=N"
set "UPD_FOUND=N"
set "HAVE_WEVTUTIL=N"
set "KP41=?"
set "EV6008=?"
set "HYP41=?"
set "BUGWER=?"
set "BUGCHECK=?"
set "UPD19=?"
set "UPD20=?"
set "UPD41=?"
set "DISKERR=?"
set "STOR129=?"
set "NTFSERR=?"
set "WHEA18=?"
set "WHEA1719=?"
set "SCMFAIL=?"
set "KPNP219=?"
set "COUNT_KP41=0"
set "COUNT_EV6008=0"
set "COUNT_HYP41=0"
set "COUNT_BUGWER=0"
set "COUNT_BUGCHECK=0"
set "COUNT_UPD19=0"
set "COUNT_UPD20=0"
set "COUNT_UPD41=0"
set "COUNT_DISKERR=0"
set "COUNT_STOR129=0"
set "COUNT_NTFSERR=0"
set "COUNT_WHEA18=0"
set "COUNT_WHEA1719=0"
set "COUNT_SCMFAIL=0"
set "COUNT_KPNP219=0"
set "LIMIT_KP41=N"
set "LIMIT_EV6008=N"
set "LIMIT_HYP41=N"
set "LIMIT_BUGWER=N"
set "LIMIT_BUGCHECK=N"
set "LIMIT_UPD19=N"
set "LIMIT_UPD20=N"
set "LIMIT_UPD41=N"
set "LIMIT_DISKERR=N"
set "LIMIT_STOR129=N"
set "LIMIT_NTFSERR=N"
set "LIMIT_WHEA18=N"
set "LIMIT_WHEA1719=N"
set "LIMIT_SCMFAIL=N"
set "LIMIT_KPNP219=N"
if not defined NOLS_TIME_STATUS set "NOLS_TIME_STATUS=UNBESTAETIGT"

if not defined WIN exit /b 1
if not exist "%WIN%:\Windows\System32\Config\SYSTEM" (
 echo ABBRUCH: Windows-Ziel nicht lesbar oder nicht vorhanden.
 exit /b 1
)
if defined LOGDIR (
 if not exist "!LOGDIR!\." (
  echo ABBRUCH: Logordner nicht erreichbar.
  exit /b 1
 )
 set "WORK=!LOGDIR!"
) else (
 if not defined TEMP set "TEMP=%SystemRoot%\Temp"
 set "WORK=!TEMP!\NOLS_ANALYSE_!RANDOM!_!RANDOM!"
 if exist "!WORK!\." (
  echo ABBRUCH: TemporÑrer Ordner ist bereits vorhanden.
  exit /b 1
 )
 md "!WORK!" >nul 2>&1
 if errorlevel 1 (
  echo ABBRUCH: TemporÑrer Ordner konnte nicht erstellt werden.
  exit /b 1
 )
 set "TEMP_CREATED=Y"
)
set "REPORT=!WORK!\95_Analysebericht.txt"
set "DETAILS=!WORK!\EventXML"
if not exist "!DETAILS!\." md "!DETAILS!" >nul 2>&1
if not exist "!DETAILS!\." (
 echo ABBRUCH: XML-Arbeitsverzeichnis konnte nicht erstellt werden.
 if "!TEMP_CREATED!"=="Y" rd /s /q "!WORK!" >nul 2>&1
 exit /b 1
)

if exist "%SystemRoot%\System32\wevtutil.exe" set "HAVE_WEVTUTIL=Y"
if exist "!OFF_SYS!" set "SYS_FOUND=Y"
for %%F in ("%WIN%:\Windows\System32\winevt\Logs\Microsoft-Windows-WindowsUpdateClient*Operational.evtx") do if exist "%%~fF" set "OFF_UPD=%%~fF"
if defined OFF_UPD set "UPD_FOUND=Y"

rem Windows filtert die Ereignisse nach Quelle UND ID.
rem Wichtig: Dateinamen der Update-EVTX koennen ein Prozentzeichen (%%4) haben.
rem Darum den EVTX-Pfad NICHT als CALL-Argument uebergeben: doppeltes
rem Percent-Expansion bei CALL wuerde ihn veraendern.
if "!HAVE_WEVTUTIL!"=="Y" if "!SYS_FOUND!"=="Y" (
 set "Q_SOURCE=!OFF_SYS!"
 call :QUERY KP41 "*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=41]]" 80
 call :QUERY EV6008 "*[System[Provider[@Name='EventLog'] and EventID=6008]]" 80
 call :QUERY HYP41 "*[System[Provider[@Name='Microsoft-Windows-Hyper-V-Hypervisor'] and EventID=41]]" 80
 call :QUERY BUGWER "*[System[Provider[@Name='Microsoft-Windows-WER-SystemErrorReporting'] and EventID=1001]]" 80
 call :QUERY BUGCHECK "*[System[Provider[@Name='BugCheck'] and EventID=1001]]" 80
)
if "!HAVE_WEVTUTIL!"=="Y" if "!UPD_FOUND!"=="Y" (
 set "Q_SOURCE=!OFF_UPD!"
 call :QUERY UPD19 "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient'] and EventID=19]]" 100
 call :QUERY UPD20 "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient'] and EventID=20]]" 100
 call :QUERY UPD41 "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient'] and EventID=41]]" 100
)
rem Erweiterte Systemereignisse: Quelle UND ID.
rem XPath mit Klammern wird ausserhalb von IF-Bloecken geparst.
if "!HAVE_WEVTUTIL!"=="Y" if "!SYS_FOUND!"=="Y" call :EXTENDED_QUERIES
call :MAKE_REPORT >"!REPORT!"
if errorlevel 1 (
 echo ABBRUCH: Bericht konnte nicht geschrieben werden.
 if "!TEMP_CREATED!"=="Y" rd /s /q "!WORK!" >nul 2>&1
 exit /b 1
)
set "WORKSHOP=!WORK!\97_Werkstattbericht.txt"
call :MAKE_WORKSHOP >"!WORKSHOP!"
if not exist "!WORKSHOP!" echo HINWEIS: Werkstattbericht konnte nicht erstellt werden.
echo.
type "!REPORT!"
echo.
if exist "!WORKSHOP!" type "!WORKSHOP!"
echo.
if "!TEMP_CREATED!"=="Y" (
 rd /s /q "!WORK!" >nul 2>&1
 if exist "!WORK!\." echo HINWEIS: TemporÑre Dateien konnten nicht entfernt werden: "!WORK!"
) else (
 echo Bericht gespeichert: "!REPORT!"
 echo XML-Einzelergebnisse: "!DETAILS!"
)
exit /b 0

:QUERY
rem QUERY: Tag, XPath, Limit. WinPE-/CMD-taugliche Zaehlung.
rem wevtutil /e:Events legt MEHRERE Ereignis-Tags in EINE XML-Zeile!
rem FOR /F zaehlt deshalb Zeilen statt Ereignisse (v2.1.1-Bug).
rem Stattdessen bestimmt eine binaere Suche die Ereigniszahl durch
rem Vergleich der Dateigroesse von /c:N und /c:LIMIT fuer dieselbe EVTX.
rem Die OFFLINE-EVTX veraendert sich waehrend der Abfragen nicht.
set "Q_TAG=%~1"
set "Q_XPATH=%~2"
set "Q_LIMIT=%~3"
set "Q_FILE=!DETAILS!\%~1.xml"
set "Q_ERROR=!DETAILS!\%~1.err.txt"
set "Q_TEST=!DETAILS!\%~1.count.tmp"
set "Q_RC=0"
"%SystemRoot%\System32\wevtutil.exe" qe "!Q_SOURCE!" /lf:true /rd:true /c:!Q_LIMIT! /f:xml /uni:false /e:Events "/q:!Q_XPATH!" 1>"!Q_FILE!" 2>"!Q_ERROR!"
set "Q_RC=!errorlevel!"
if not "!Q_RC!"=="0" (
 set "%~1=?"
 echo [HINWEIS] Abfrage %~1 fehlgeschlagen, wevtutil-RC !Q_RC!.
 exit /b 0
)
if not exist "!Q_FILE!" (
 set "%~1=?"
 echo [HINWEIS] Abfrage %~1 ohne XML-Ausgabedatei.
 exit /b 0
)
for %%Z in ("!Q_FILE!") do set "Q_FULL_SIZE=%%~zZ"
rem Leeres /e:Events-Ergebnis ist unter WinPE genau 21 Byte lang.
rem Keine leeren Resultate als positive Befunde ausgeben.
if !Q_FULL_SIZE! LSS 21 (
 set "%~1=?"
 echo [HINWEIS] Abfrage %~1 liefert kein gueltiges XML-Dokument.
 exit /b 0
)
if !Q_FULL_SIZE! EQU 21 (
 set "%~1=0"
 set "COUNT_%~1=0"
 exit /b 0
)
set /a "Q_LOW=1,Q_HIGH=Q_LIMIT"
:Q_BINARY_LOOP
if !Q_LOW! GEQ !Q_HIGH! goto :Q_BINARY_DONE
set /a "Q_MID=(Q_LOW+Q_HIGH)/2"
"%SystemRoot%\System32\wevtutil.exe" qe "!Q_SOURCE!" /lf:true /rd:true /c:!Q_MID! /f:xml /uni:false /e:Events "/q:!Q_XPATH!" 1>"!Q_TEST!" 2>>"!Q_ERROR!"
if errorlevel 1 (
 set "%Q_TAG%=?"
 echo [HINWEIS] Zaehl-Abfrage !Q_TAG! fehlgeschlagen.
 if exist "!Q_TEST!" del /q "!Q_TEST!" >nul 2>&1
 exit /b 0
)
for %%Z in ("!Q_TEST!") do set "Q_MID_SIZE=%%~zZ"
if !Q_MID_SIZE! GEQ !Q_FULL_SIZE! (
 set /a "Q_HIGH=Q_MID"
) else (
 set /a "Q_LOW=Q_MID+1"
)
goto :Q_BINARY_LOOP
:Q_BINARY_DONE
if exist "!Q_TEST!" del /q "!Q_TEST!" >nul 2>&1
set "%Q_TAG%=!Q_LOW!"
set "COUNT_%Q_TAG%=!Q_LOW!"
if !Q_LOW! GEQ !Q_LIMIT! set "LIMIT_%Q_TAG%=Y"
exit /b 0

:EXTENDED_QUERIES
set "Q_SOURCE=!OFF_SYS!"
call :QUERY DISKERR "*[System[Provider[@Name='disk'] and (EventID=7 or EventID=11 or EventID=51 or EventID=153 or EventID=157)]]" 32
call :QUERY STOR129 "*[System[(Provider[@Name='storahci'] or Provider[@Name='stornvme'] or Provider[@Name='storport'] or Provider[@Name='iaStorA'] or Provider[@Name='iaStorAC']) and EventID=129]]" 32
call :QUERY NTFSERR "*[System[(Provider[@Name='Ntfs'] or Provider[@Name='Microsoft-Windows-Ntfs']) and (EventID=55 or EventID=98 or EventID=140)]]" 32
call :QUERY WHEA18 "*[System[Provider[@Name='Microsoft-Windows-WHEA-Logger'] and EventID=18]]" 32
call :QUERY WHEA1719 "*[System[Provider[@Name='Microsoft-Windows-WHEA-Logger'] and (EventID=17 or EventID=19)]]" 32
call :QUERY SCMFAIL "*[System[Provider[@Name='Service Control Manager'] and (EventID=7000 or EventID=7023 or EventID=7031 or EventID=7034)]]" 32
call :QUERY KPNP219 "*[System[Provider[@Name='Microsoft-Windows-Kernel-PnP'] and EventID=219]]" 32
exit /b 0

:MAKE_REPORT
echo ================================================================
echo           IT-WERKSTATT TOOLKIT v2.4.2 - AUSWERTUNG
echo ================================================================
echo Ziel: %WIN%:\Windows
echo AusgewÑhltes Fehlerbild: %CASE%
echo Sicherheit: NUR DIAGNOSE - KEINE REPARATUREN
echo Datenquelle: offline Windows-Ereignisdateien
echo.
echo [1] WINDOWS / STARTDATEIEN
if exist "%WIN%:\Windows\System32\winload.efi" (
 echo [BEFUND] winload.efi ist vorhanden.
) else (
 echo [HINWEIS] winload.efi fehlt oder ist nicht lesbar.
)
if exist "%WIN%:\Windows\System32\Config\SYSTEM" (
 echo [BEFUND] SYSTEM-Registrydatei ist vorhanden.
) else (
 echo [HINWEIS] SYSTEM-Registrydatei fehlt oder ist nicht lesbar.
)
echo Eine vorhandene Datei beweist keinen fehlerfreien Start.
echo.
echo [2] ABSTURZDATEIEN
if exist "%WIN%:\Windows\Minidump\*.dmp" (
 echo [BEFUND] Mindestens eine Minidump-Datei vorhanden.
) else (
 echo [OFFEN] Keine Minidumps gefunden oder Zugriff eingeschrÑnkt.
)
if exist "%WIN%:\Windows\MEMORY.DMP" (
 echo [BEFUND] MEMORY.DMP ist vorhanden.
) else (
 echo [OFFEN] MEMORY.DMP nicht gefunden oder Zugriff eingeschrÑnkt.
)
echo Ohne Dumpanalyse ist keine Absturzursache nachgewiesen.
echo.
echo [3] SYSTEMEREIGNISSE - OFFLINE
if "!HAVE_WEVTUTIL!"=="N" echo [OFFEN] wevtutil ist in dieser WinPE-Umgebung nicht vorhanden.
if "!SYS_FOUND!"=="N" echo [OFFEN] System.evtx nicht vorhanden oder nicht lesbar.
call :REPORT_COUNT KP41 "Kernel-Power ID 41" 80
call :REPORT_COUNT EV6008 "EventLog ID 6008" 80
call :REPORT_COUNT HYP41 "Hyper-V-Hypervisor ID 41 (NICHT Kernel-Power)" 80
call :REPORT_COUNT BUGWER "WER-SystemErrorReporting ID 1001" 80
call :REPORT_COUNT BUGCHECK "BugCheck ID 1001" 80
if not "!KP41!"=="?" if !KP41! GTR 0 echo [HINWEIS] Unerwarteter Neustart erkannt; Ursache unbekannt.
if not "!EV6008!"=="?" if !EV6008! GTR 0 echo [HINWEIS] Unsauberes Herunterfahren; kein Ursachenbeweis.
echo.
echo [4] WINDOWS UPDATE - OFFLINE
if "!UPD_FOUND!"=="N" echo [OFFEN] WindowsUpdateClient-Operational.evtx fehlt.
call :REPORT_COUNT UPD19 "UpdateClient ID 19 (Installation erfolgreich)" 100
call :REPORT_COUNT UPD20 "UpdateClient ID 20 (Installation fehlgeschlagen)" 100
call :REPORT_COUNT UPD41 "UpdateClient ID 41 (KEIN Kernel-Power)" 100
if not "!UPD20!"=="?" if !UPD20! GTR 0 echo [HINWEIS] Update-Fehlercode im XML-Original nachlesen.
if exist "%WIN%:\Windows\WinSxS\pending.xml" (
 echo [HINWEIS] pending.xml vorhanden; allein kein Updatefehler-Beweis.
)
echo.
echo [5] ERWEITERTE SYSTEMEREIGNISSE - OFFLINE
call :REPORT_COUNT DISKERR "Datentraeger disk IDs 7/11/51/153/157" 32
call :REPORT_COUNT STOR129 "Speichercontroller Reset ID 129" 32
call :REPORT_COUNT NTFSERR "NTFS IDs 55/98/140" 32
call :REPORT_COUNT WHEA18 "WHEA-Logger ID 18" 32
call :REPORT_COUNT WHEA1719 "WHEA-Logger IDs 17/19" 32
call :REPORT_COUNT SCMFAIL "Service Control Manager Ausfaelle" 32
call :REPORT_COUNT KPNP219 "Kernel-PnP ID 219" 32
if not "!DISKERR!"=="?" if !DISKERR! GTR 0 echo [HINWEIS] Datentraegermeldungen: Datensicherung/SMART zuerst pruefen.
if not "!NTFSERR!"=="?" if !NTFSERR! GTR 0 echo [HINWEIS] NTFS-Meldungen: Dateisystemzustand untersuchen.
if not "!WHEA18!"=="?" if !WHEA18! GTR 0 echo [HINWEIS] WHEA 18: Hardwareereignis im Original pruefen.
if not "!STOR129!"=="?" if !STOR129! GTR 0 echo [HINWEIS] Controller-Reset: Kabel, Treiber, Datentraeger testen.
echo Unterschiedliche Quellen nutzen verschiedene Ereignis-IDs.
echo Fehlende Treffer sind keine Entwarnung.
echo.
echo [6] EMPFOHLENE NéCHSTE SCHRITTE
if not "!KP41!"=="?" if !KP41! GTR 0 echo - Neustartzeit mit Treibern, Updates und Stromversorgung abgleichen.
if not "!EV6008!"=="?" if !EV6008! GTR 0 echo - RAM, SSD und Stromversorgung bei wiederholten Problemen prÅfen.
if not "!BUGWER!"=="?" if !BUGWER! GTR 0 echo - Bugcheck-Code und Dump mit einem Debugger untersuchen.
if not "!BUGCHECK!"=="?" if !BUGCHECK! GTR 0 echo - Bugcheck-Code und Dump mit einem Debugger untersuchen.
if not "!UPD20!"=="?" if !UPD20! GTR 0 echo - Windows-Update-Fehlercode und CBS/DISM-Logs prÅfen.
if "%CASE%"=="1" echo - EFI-/BCD-Diagnose unter HauptmenÅ [6] durchfÅhren.
if "%CASE%"=="2" echo - Bei Bluescreens Treiber, RAM und vorhandene Dumps untersuchen.
if "%CASE%"=="3" echo - SMART, Ressourcenlast und Autostart im Windows-Desktop prÅfen.
if "%CASE%"=="4" echo - DISM CheckHealth und CBS-Logs prÅfen.
if "%CASE%"=="5" echo - Zeitpunkt, Temperaturen, Treiber und RAM vergleichen.
if "%CASE%"=="6" echo - Netzwerk im regulÑr gestarteten Windows separat prÅfen.
if "%CASE%"=="7" echo - Fehlerzeitpunkt und letzte énderungen dokumentieren.
echo.
echo GRENZEN:
echo - Bis zu 80 Treffer je Systemquelle, 100 je Updatequelle.
echo - Wenn das Limit erreicht wird: mindestens so viele, evtl. mehr.
echo - Alle Abfragen sind unabhÑngig; keine systemweite Gesamtzahl.
echo - Erweiterte Ereignisse: maximal 32 je Kategorie.
echo - Zeitliche Korrelation wird NICHT automatisch bewiesen.
echo - UTC-Zeiten der EventXML-Dateien vor Ort vergleichen.
echo - Ereignis-ID 41 hat je nach Quelle verschiedene Bedeutungen.
echo - Fehlen von Dumps/Ereignissen ist keine Entwarnung.
echo - Bei fehlgeschlagenen XML-Abfragen wird OFFEN angezeigt.
echo ================================================================
exit /b 0


:MAKE_WORKSHOP
rem Kompakter, vorsichtiger Werkstattbericht. Nur Diagnose.
echo ================================================================
echo          IT-WERKSTATT TOOLKIT v2.4.2 - WERKSTATTBERICHT
echo ================================================================
echo Entwicklung: Nols
echo Zielsystem: %WIN%:\Windows
echo Fehlerbild-Code: %CASE%
echo Zeitquelle: aktuell gestartetes WinPE ^(lokale Anzeige^).
echo Uhrzeit durch Nutzer bestaetigt: !NOLS_TIME_STATUS!
echo WinPE-Datum:
date /t
echo WinPE-Uhrzeit:
time /t
echo Ereigniszeiten in XML sind UTC; lokale Zeitzone beachten.
echo.
echo STATUS
if exist "%WIN%:\Windows\System32\Config\SYSTEM" (
 echo [BEFUND] Windows-Registrydatei lesbar.
) else (
 echo [OFFEN] Windows-Registrydatei nicht lesbar.
)
if exist "%WIN%:\Windows\Minidump\*.dmp" (
 echo [BEFUND] Minidump-Dateien vorhanden; Inhalt ungeprueft.
) else (
 echo [OFFEN] Keine Minidumps gefunden; Ursache unbekannt.
)
call :WORKSHOP_LINE KP41 "Kernel-Power 41 (Neustart)"
call :WORKSHOP_LINE EV6008 "EventLog 6008 (Shutdown)"
call :WORKSHOP_LINE UPD20 "Windows Update Installationsfehler"
call :WORKSHOP_LINE DISKERR "Datentraegerereignisse"
call :WORKSHOP_LINE STOR129 "Speichercontroller-Resets"
call :WORKSHOP_LINE NTFSERR "Dateisystemereignisse"
call :WORKSHOP_LINE WHEA18 "WHEA 18 Hardwareereignisse"
call :WORKSHOP_LINE WHEA1719 "WHEA 17/19 korrigierte Meldungen"
call :WORKSHOP_LINE SCMFAIL "Dienst-/Treiberstartprobleme"
call :WORKSHOP_LINE KPNP219 "PnP-Treiberwarnungen"
echo.
echo EMPFOHLENE VORGEHENSWEISE
if not "!DISKERR!"=="?" if !DISKERR! GTR 0 echo - Vor intensiven Scans Datensicherung, SMART und Anschluesse pruefen.
if not "!STOR129!"=="?" if !STOR129! GTR 0 echo - Controller, Speicherpfad und Treiber im Zielsystem pruefen.
if not "!NTFSERR!"=="?" if !NTFSERR! GTR 0 echo - Dateisystemereignisse mit betroffenen Volumes abgleichen.
if not "!WHEA18!"=="?" if !WHEA18! GTR 0 echo - WHEA-Originaleintrag und Hardware-Stresstest getrennt bewerten.
if not "!UPD20!"=="?" if !UPD20! GTR 0 echo - Updatefehler im XML und CBS-Protokoll nachverfolgen.
if not "!KP41!"=="?" if !KP41! GTR 0 echo - Neustarts mit anderen Ereignissen zeitlich vergleichen.
if "!NOLS_TIME_STATUS!"=="NICHT_BESTAETIGT" echo - WinPE-Systemzeit vor Verwendung der Fallzeitstempel kontrollieren.
echo - Befunde und Uhrzeiten mit den EventXML-Originalen abgleichen.
echo - Keine Reparaturen wurden durch diese Auswertung gestartet.
echo.
echo BEWERTUNGSGRENZEN
echo - Stichproben mit Abfragelimits; nicht das gesamte Ereignisarchiv.
echo - Ein Treffer allein beweist keine Fehlerursache.
echo - Null Treffer bedeutet NICHT, dass das Zielsystem gesund ist.
echo - Zeitliche Naehe ist kein Kausalitaetsbeweis.
echo - Kein automatisch ermittelter SMART-/RAM-/Treiberdefekt.
echo ================================================================
exit /b 0

:WORKSHOP_LINE
set "WS_VALUE=!%~1!"
set "WS_LABEL=%~2"
if "!WS_VALUE!"=="?" (
 echo [OFFEN] !WS_LABEL!: nicht auswertbar.
) else (
 if "!WS_VALUE!"=="0" (
  echo [INFO] !WS_LABEL!: 0 Treffer in begrenzter Stichprobe.
 ) else (
  echo [BEFUND] !WS_LABEL!: !WS_VALUE! Treffer in Stichprobe.
 )
)
exit /b 0

:REPORT_COUNT
rem Label wird via delayed expansion eingefuegt. Dadurch zerstoeren
rem Klammern in Bezeichnungen wie "(NICHT Kernel-Power)" kein IF-Block.
set "REPORT_LABEL=%~2"
set "VALUE=!%~1!"
if "!VALUE!"=="?" (
 echo [OFFEN] !REPORT_LABEL!: nicht zuverlaessig auswertbar.
 exit /b 0
)
if !VALUE! GEQ %~3 (
 echo [BEFUND] !REPORT_LABEL!: mindestens !VALUE! ^(Abfragelimit erreicht^).
) else (
 echo [BEFUND] !REPORT_LABEL!: !VALUE! Treffer in der abgefragten Quelle.
)
exit /b 0
