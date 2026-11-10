@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem v2.4.2: SCM-Ereignis-IDs separat; kein DISM /Remove-Driver.
chcp 850 >nul 2>&1
set "M=%~dp0"
set "WIN=%~1"
set "OUT="
set "KEEP=N"
set "FROM_CASE=N"
set "E_BUGCHECK=?"
set "E_KERNEL_PNP=?"
set "E_DIENSTE=?"
set "E_SCM7000=?"
set "E_SCM7023=?"
set "E_SCM7031=?"
set "E_SCM7034=?"
set "DISM_RC=?"
if /I "%~3"=="IN_CASE" set "FROM_CASE=Y"
if not defined WIN call "%M%ChooseDrive.cmd" WIN WINDOWS
if not defined WIN exit /b 1
set "VALID=N"
for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if /I "!WIN!"=="%%L" set "VALID=Y"
if "!VALID!"=="N" (
 echo ABBRUCH: Laufwerksbuchstabe ungueltig.
 exit /b 1
)
if not exist "!WIN!:\Windows\System32\Config\SYSTEM" (
 echo ABBRUCH: Windows-Ziel fehlt.
 exit /b 1
)
if "!FROM_CASE!"=="Y" (
 if not "%~2"=="" (
  set "OUT=%~2\v24_BSOD_Treiber"
  set "KEEP=Y"
 )
) else (
 echo.
 set "ANSWER="
 set /p "ANSWER=Sollen Logs auf dem Toolkit-Laufwerk erstellt werden? [Y/N, Enter=N]: "
 if /I "!ANSWER!"=="Y" (
  set "NOLS_SAVE_LOGS=Y"
  call "%M%MakeLogDir.cmd" OUT BSOD_TREIBER
  if errorlevel 1 exit /b 1
  set "KEEP=Y"
 )
)
if "!KEEP!"=="N" (
 if not defined TEMP set "TEMP=%SystemRoot%\Temp"
 set "OUT=!TEMP!\NOLS_V24_!RANDOM!_!RANDOM!"
)
if not exist "!OUT!\." md "!OUT!" >nul 2>&1
if not exist "!OUT!\." (
 echo ABBRUCH: Arbeitsordner nicht schreibbar.
 exit /b 1
)
md "!OUT!\EventXML" >nul 2>&1
cls
echo ================================================================
echo          IT-WERKSTATT TOOLKIT - BSOD / TREIBERANALYSE
echo ================================================================
echo Windows: !WIN!:\Windows
echo Eine gelistete .sys oder .inf beweist keine Absturzursache.
echo Kein automatisches Entfernen oder Aendern von Treibern.
echo.
call :DUMPS
call :EVENTS
call :DRIVERS
call :REPORT >"!OUT!\90_BSOD_Treiberbericht.txt"
type "!OUT!\90_BSOD_Treiberbericht.txt"
echo.
if "!KEEP!"=="Y" (
 echo Dateien: "!OUT!"
 echo Optional am Linux-Laptop:
 echo python3 Recovery/Analyse/offline_analyse.py "!OUT!" --mode bsod
) else (
 rd /s /q "!OUT!" >nul 2>&1
 if exist "!OUT!\." echo HINWEIS: Tempdaten konnten nicht entfernt werden.
)
exit /b 0

:DUMPS
>"!OUT!\10_Dumps.txt" echo IT-WERKSTATT TOOLKIT v2.4.2 - Dump-Fundstellen; KEINE Speicherabbildanalyse
if exist "!WIN!:\Windows\Minidump\*.dmp" (
 echo [BEFUND] Minidumps vorhanden:
 dir /a:-d /o:-d "!WIN!:\Windows\Minidump\*.dmp" >>"!OUT!\10_Dumps.txt" 2>&1
 type "!OUT!\10_Dumps.txt"
 set "HAS_DUMP=Y"
) else (
 echo Keine Minidumps gefunden oder Ordner nicht lesbar.
 >>"!OUT!\10_Dumps.txt" echo Minidump: nicht gefunden/nicht lesbar
)
if exist "!WIN!:\Windows\MEMORY.DMP" (
 set "HAS_DUMP=Y"
 dir /a:-d "!WIN!:\Windows\MEMORY.DMP" >>"!OUT!\10_Dumps.txt" 2>&1
 echo [BEFUND] MEMORY.DMP vorhanden.
) else (
 echo MEMORY.DMP fehlt oder ist nicht lesbar.
 >>"!OUT!\10_Dumps.txt" echo MEMORY.DMP: nicht gefunden/nicht lesbar
)
exit /b 0

:EVENTS
set "EVT=!WIN!:\Windows\System32\winevt\Logs\System.evtx"
if not exist "!EVT!" (
 echo [OFFEN] System.evtx fehlt.
 exit /b 0
)
if not exist "%SystemRoot%\System32\wevtutil.exe" (
 echo [OFFEN] wevtutil fehlt.
 exit /b 0
)
set "Q_BUG=*[System[(Provider[@Name='Microsoft-Windows-WER-SystemErrorReporting'] or Provider[@Name='BugCheck']) and EventID=1001]]"
set "Q_KPNP=*[System[Provider[@Name='Microsoft-Windows-Kernel-PnP'] and EventID=219]]"
set "Q_SCM=*[System[Provider[@Name='Service Control Manager'] and (EventID=7000 or EventID=7023 or EventID=7031 or EventID=7034)]]"
call :FETCH "BUGCHECK" "!Q_BUG!" 60
call :FETCH "KERNEL_PNP" "!Q_KPNP!" 60
call :FETCH "DIENSTE" "!Q_SCM!" 60
rem Die Einzelabfragen trennen Dienststartfehler von unerwartetem Dienstende.
set "Q_SCM7000=*[System[Provider[@Name='Service Control Manager'] and EventID=7000]]"
set "Q_SCM7023=*[System[Provider[@Name='Service Control Manager'] and EventID=7023]]"
set "Q_SCM7031=*[System[Provider[@Name='Service Control Manager'] and EventID=7031]]"
set "Q_SCM7034=*[System[Provider[@Name='Service Control Manager'] and EventID=7034]]"
call :FETCH "SCM7000" "!Q_SCM7000!" 1
call :FETCH "SCM7023" "!Q_SCM7023!" 1
call :FETCH "SCM7031" "!Q_SCM7031!" 1
call :FETCH "SCM7034" "!Q_SCM7034!" 1
exit /b 0

:FETCH
"%SystemRoot%\System32\wevtutil.exe" qe "!EVT!" /lf:true /rd:true /f:xml /uni:false /e:Events /c:%~3 "/q:%~2" 1>"!OUT!\EventXML\%~1.xml" 2>"!OUT!\EventXML\%~1.err.txt"
if errorlevel 1 (
 set "E_%~1=?"
 echo [OFFEN] %~1: wevtutil-Abfrage fehlgeschlagen.
 exit /b 0
)
for %%Z in ("!OUT!\EventXML\%~1.xml") do set "FSIZE=%%~zZ"
if !FSIZE! LEQ 21 (set "E_%~1=N") else (set "E_%~1=Y")
exit /b 0

:DRIVERS
if not exist "%SystemRoot%\System32\dism.exe" (
 echo [OFFEN] DISM fehlt in dieser WinPE-Umgebung.
 exit /b 0
)
echo.
echo Offline-Drittanbietertreiber: DISM /Get-Drivers
 echo Treiber werden NICHT deaktiviert, entfernt oder geaendert.
"%SystemRoot%\System32\dism.exe" /Image:!WIN!:\ /Get-Drivers /Format:List "/LogPath:!OUT!\DISM_Detail.log" 1>"!OUT!\20_Treiber_Drittanbieter.txt" 2>&1
set "DISM_RC=!errorlevel!"
if not "!DISM_RC!"=="0" (
 echo [OFFEN] DISM konnte die Treiberliste nicht erstellen; RC=!DISM_RC!.
 type "!OUT!\20_Treiber_Drittanbieter.txt"
 exit /b 0
)
echo [OK] Treiberinventur gespeichert/temporar erstellt.
set "SHOW_LIST="
set /p "SHOW_LIST=Komplette DISM-Treiberliste anzeigen? [Y/N, Enter=N]: "
if /I "!SHOW_LIST!"=="Y" type "!OUT!\20_Treiber_Drittanbieter.txt"
echo.
echo Details zu einem bestimmten oemNN.inf koennen nachgeschlagen werden.
set "INF="
set /p "INF=Optional: OEM-INF Nummer (z.B. 12, Enter=ueberspringen): "
if not defined INF exit /b 0
set "IOK=N"
for /L %%N in (0,1,9999) do if "!INF!"=="%%N" set "IOK=Y"
if "!IOK!"=="N" (
 echo Ungueltige Treibernummer; uebersprungen.
 exit /b 0
)
"%SystemRoot%\System32\dism.exe" /Image:!WIN!:\ /Get-DriverInfo /Driver:oem!INF!.inf "/LogPath:!OUT!\DISM_Detail.log" 1>"!OUT!\21_Detail_oem!INF!.txt" 2>&1
if errorlevel 1 echo [OFFEN] DISM /Get-DriverInfo meldet Fehler; Originalausgabe lesen.
type "!OUT!\21_Detail_oem!INF!.txt"
exit /b 0

:REPORT
echo ================================================================
echo               IT-WERKSTATT - BSOD / TREIBER
echo ================================================================
echo Ziel: !WIN!:\Windows
echo.
if "!HAS_DUMP!"=="Y" (echo [BEFUND] Mindestens ein Speicherabbild vorhanden.) else (echo [OFFEN] Keine Dumpdatei gefunden oder nicht lesbar.)
if "!E_BUGCHECK!"=="Y" echo [BEFUND] Bugcheck-1001-Ereignisse in Stichprobe vorhanden.
if "!E_BUGCHECK!"=="N" echo [INFO] Kein Bugcheck-1001-Treffer in Stichprobe.
if "!E_BUGCHECK!"=="?" echo [OFFEN] Bugcheck-Ereignisabfrage fehlgeschlagen.
if "!E_KERNEL_PNP!"=="Y" echo [HINWEIS] Kernel-PnP-219-Ereignisse vorhanden.
if "!E_DIENSTE!"=="Y" echo [HINWEIS] Dienst-/Komponentenereignisse vorhanden.
echo   SCM 7000: !E_SCM7000!  / 7023: !E_SCM7023!
echo   SCM 7031: !E_SCM7031!  / 7034: !E_SCM7034!
echo   Y = mindestens ein Ereignis, N = kein Treffer, ? = nicht auswertbar.
echo   Details pro Dienst: Linux-Nachauswerter v2.4.2.
if "!DISM_RC!"=="0" (echo [BEFUND] Offline-Drittanbietertreiber inventarisiert.) else (echo [OFFEN] Treiberinventur unvollstaendig oder nicht ausfuehrbar.)
echo.
echo Grenzen:
echo - Ein .inf-Paket beweist NICHT, dass Treiber zum Absturz geladen war.
echo - 219/7000/7023/7031/7034 sind Hinweise, keine Treiberschuld.
echo - Dump-Inhalte erfordern einen kompatiblen Debugger ausserhalb
 echo   der Standard-WinPE-Umgebung; keine automatische Verursacher-These.
echo - Verfuegbare Dateien: 10_Dumps.txt, 20_Treiber_Drittanbieter.txt,
echo   EventXML/*.xml und ggf. 21_Detail_oemNN.txt.
echo - WinDbg/CDB auf normalem Windows-PC mit passenden Symbolen nutzen.
echo - Keinerlei Treiberveraenderungen durch dieses Modul.
echo ================================================================
exit /b 0
