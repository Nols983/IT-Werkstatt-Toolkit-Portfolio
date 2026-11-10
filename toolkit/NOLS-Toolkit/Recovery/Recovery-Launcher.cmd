@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem IT-WERKSTATT TOOLKIT v2.4.2 RC3 - OEM 850.
rem Windows-PE/RE-CMD; keine PowerShell und kein Browser erforderlich.
chcp 850 >nul 2>&1
set "MOD=%~dp0Modules"
if not exist "%MOD%\TimeCheck.cmd" (
    echo FEHLER: ZeitprÅfung fehlt: "%MOD%\TimeCheck.cmd"
    exit /b 1
)
if not exist "%MOD%\ChooseDrive.cmd" (
    echo FEHLER: Recovery-Module fehlen: "%MOD%"
    exit /b 1
)
if /I not "%ITW_SKIP_TIMECHECK%"=="1" call "%MOD%\TimeCheck.cmd"
set "ITW_SKIP_TIMECHECK="
:MAIN
cls
echo ================================================================
echo                       IT-WERKSTATT TOOLKIT
echo                        Version 2.4.2 RC3
echo                        Entwicklung: Nols
echo ================================================================
echo.
echo   DIAGNOSE - NUR LESEN
echo   ------------------------------------------------------------
echo   [1] Einzelpruefungen        - CHKDSK, DISM und SFC
echo   [2] Auto-Diagnose           - Kombinierte Systemchecks
echo   [3] Fehleranalyse           - Gefuehrte Fehlersuche
echo   [4] Datentraeger / I/O      - NTFS und Speichercontroller
echo   [5] BSOD / Treiber          - Treiberinfos und Dump-Suche
echo   [6] Hardware / Windows 11   - CPU, RAM, SSD, GPU, Board
echo.
echo   REPARATUR - AENDERT DATEN
echo   ------------------------------------------------------------
echo   [A] Einzelreparaturen       - SFC, DISM und CHKDSK /f
echo   [B] Auto-Reparatur          - Kombinierter Reparaturlauf
echo   [C] Boot-Werkzeuge          - UEFI / BCD mit Sicherung
echo.
echo   WEITERE FUNKTIONEN
echo   ------------------------------------------------------------
echo   [W] Tastatur                - Deutsch / Englisch
echo   [X] Berichte                - Gespeicherte Protokolle
echo   [Y] Zeitpruefung            - WinPE-Uhr kontrollieren
echo   [Z] Hinweise                - Anleitung und Sicherheit
echo.
echo   SYSTEM
echo   ------------------------------------------------------------
echo   [8] Neustarten     [9] Herunterfahren     [0] CMD
echo ================================================================
set "A="
set /p "A=Auswahl: "
if "!A!"=="0" exit /b 0
if "!A!"=="1" goto DIAG
if "!A!"=="2" goto AUTO_DIAG
if "!A!"=="3" goto FEHLERANALYSE
if "!A!"=="4" goto STORAGE_ANALYSIS
if "!A!"=="5" goto BSOD_DRIVERS
if "!A!"=="6" goto HARDWARE_INVENTORY
if /I "!A!"=="A" goto REPAIR
if /I "!A!"=="B" goto AUTO_REPAIR
if /I "!A!"=="C" goto BOOT_MENU
if /I "!A!"=="W" goto KEYBOARD_MENU
if /I "!A!"=="X" goto ANALYZE
if /I "!A!"=="Y" goto TIME_MENU
if /I "!A!"=="Z" goto INFO
if "!A!"=="8" goto REBOOT
if "!A!"=="9" goto POWEROFF
echo Ungueltige Auswahl. Bitte einen Menuepunkt waehlen.
pause
goto MAIN

:DIAG
cls
echo ================================================================
echo                    DIAGNOSE - NUR LESEN
echo ================================================================
echo.
echo   [1] DatentrÑger und Volumes anzeigen
echo   [2] Windows-Installationen suchen
echo   [3] CHKDSK  - Dateisystem prÅfen (ohne /f)
echo   [4] DISM    - /CheckHealth (offline)
echo   [5] DISM    - /ScanHealth (offline)
echo   [6] SFC     - /verifyonly (offline)
echo   [7] Netzwerkstatus
echo   [8] Ziel-Windows / BCD untersuchen (nur lesen)
echo   [9] Auto-Diagnose - auch im Hauptmenue [2]
echo.
echo   [0] ZurÅck zum HauptmenÅ
echo ================================================================
set "A="
set /p "A=Auswahl: "
if "!A!"=="0" goto MAIN
if "!A!"=="1" goto D1
if "!A!"=="2" goto D2
if "!A!"=="3" goto D3
if "!A!"=="4" goto D4
if "!A!"=="5" goto D5
if "!A!"=="6" goto D6
if "!A!"=="7" goto D7
if "!A!"=="8" goto D8
if "!A!"=="9" goto AUTO_DIAG
echo Ungueltige Auswahl.
pause
goto DIAG
:D1
call :ASK_LOGS
call "%MOD%\RunReadOnlyLogged.cmd" "%MOD%\Volumes.cmd"
goto DIAG_PAUSE
:D2
call :ASK_LOGS
call "%MOD%\RunReadOnlyLogged.cmd" "%MOD%\WindowsSearch.cmd"
goto DIAG_PAUSE
:D3
call :ASK_LOGS
call "%MOD%\ChkdskReadOnly.cmd"
goto DIAG_PAUSE
:D4
call :ASK_LOGS
call "%MOD%\DismCheckHealth.cmd"
goto DIAG_PAUSE
:D5
call :ASK_LOGS
call "%MOD%\DismScanHealth.cmd"
goto DIAG_PAUSE
:D6
call :ASK_LOGS
call "%MOD%\SfcVerifyOnly.cmd"
goto DIAG_PAUSE
:D7
call :ASK_LOGS
call "%MOD%\RunReadOnlyLogged.cmd" "%MOD%\NetworkInfo.cmd"
goto DIAG_PAUSE
:D8
call :ASK_LOGS
call "%MOD%\BootDiagnose.cmd"
goto DIAG_PAUSE
:DIAG_PAUSE
echo.
pause
goto DIAG

:REPAIR
cls
echo ================================================================
echo                  REPARATUR - AENDERT DATEN
echo ================================================================
echo.
echo   [1] SFC     - Offline-Windows /scannow
echo   [2] DISM    - Offline-Windows /RestoreHealth
echo   [3] CHKDSK  - Dateisystem reparieren /f
echo   [4] Auto-Reparatur - auch im Hauptmenue [B]
echo   [5] EFI / BCD - auch im Hauptmenue [C]
echo   [6] Reparatur-Fahrplan anzeigen
echo.
echo   [0] ZurÅck zum HauptmenÅ
echo ================================================================
echo WARNUNG: Reparaturen kînnen Daten verÑndern.
echo Vorher Backup und Zielvolume prÅfen.
set "A="
set /p "A=Auswahl: "
if "!A!"=="0" goto MAIN
if "!A!"=="1" goto R1
if "!A!"=="2" goto R2
if "!A!"=="3" goto R3
if "!A!"=="4" goto AUTO_REPAIR
if "!A!"=="5" goto BOOT_INFO
if "!A!"=="6" goto R6
echo Ungueltige Auswahl.
pause
goto REPAIR
:R1
call :ASK_LOGS
call "%MOD%\SfcRepair.cmd"
goto REPAIR_PAUSE
:R2
call :ASK_LOGS
call "%MOD%\DismRestoreHealth.cmd"
goto REPAIR_PAUSE
:R3
call :ASK_LOGS
call "%MOD%\ChkdskRepair.cmd"
goto REPAIR_PAUSE
:R6
call "%MOD%\RepairGuide.cmd"
goto REPAIR_PAUSE
:BOOT_INFO
goto BOOT_MENU
:REPAIR_PAUSE
echo.
pause
goto REPAIR

:BOOT_MENU
cls
echo ================================================================
echo                      BOOT-WERKZEUGE
echo ================================================================
echo.
echo   [1] Bootdiagnose: Firmware, BitLocker und Ziel-BCD
echo   [2] UEFI-Bootdateien reparieren (BCDBoot)
echo   [3] Anleitung zur EFI-Partition
echo.
echo   [0] ZurÅck zum HauptmenÅ
echo ================================================================
set "A="
set /p "A=Auswahl: "
if "!A!"=="0" goto MAIN
if "!A!"=="1" goto BOOT_DIAG
if "!A!"=="2" goto BOOT_FIX
if "!A!"=="3" goto BOOT_HELP
echo Ungueltige Auswahl.
pause
goto BOOT_MENU
:BOOT_DIAG
call :ASK_LOGS
call "%MOD%\BootDiagnose.cmd"
echo.
pause
goto BOOT_MENU
:BOOT_FIX
call :ASK_LOGS
call "%MOD%\BootRepairUEFI.cmd"
echo.
pause
goto BOOT_MENU
:BOOT_HELP
type "%~dp0Docs\BOOT-LEITFADEN.txt"
echo.
pause
goto BOOT_MENU

:KEYBOARD_MENU
cls
echo ================================================================
echo                      TASTATUR WECHSELN
echo ================================================================
echo.
echo   [1] Deutsch  - QWERTZ
echo   [2] Englisch - QWERTY
echo.
echo   [0] Zurueck zum Hauptmenue
echo ================================================================
set "KBD_CHOICE="
set "KBD_ID="
set /p "KBD_CHOICE=Auswahl: "
if "!KBD_CHOICE!"=="0" goto MAIN
if "!KBD_CHOICE!"=="1" set "KBD_ID=0407:00000407"
if "!KBD_CHOICE!"=="2" set "KBD_ID=0409:00000409"
if not defined KBD_ID (
    echo Ungueltige Auswahl.
    pause
    goto KEYBOARD_MENU
)
if not exist "%SystemRoot%\System32\wpeutil.exe" (
    echo FEHLER: wpeutil.exe ist in dieser Umgebung nicht verfuegbar.
    echo Tastaturlayout wurde NICHT geaendert.
    pause
    goto KEYBOARD_MENU
)
echo.
echo Schalte Tastatur um ...
"%SystemRoot%\System32\wpeutil.exe" SetKeyboardLayout !KBD_ID!
if errorlevel 1 (
    echo FEHLER: Windows PE konnte die Tastatur nicht umstellen.
    echo Bei Bedarf das Layout in der WinPE-ISO konfigurieren.
    pause
    goto KEYBOARD_MENU
)
echo.
echo Befehl erfolgreich. Starte eine NEUE CMD-Konsole.
echo Teste anschliessend Y und Z: eine Erfolgsmeldung garantiert
echo noch nicht, dass die physische Tastatur richtig belegt ist.
echo.
set "ITW_SKIP_TIMECHECK=1"
start "" /wait "%ComSpec%" /d /c call "%~f0"
exit /b 0
:TIME_MENU
call "%MOD%\TimeCheck.cmd"
goto MAIN
:FEHLERANALYSE
call "%MOD%\Fehleranalyse.cmd"
echo.
pause
goto MAIN
:ANALYZE
call "%MOD%\BerichteMenu.cmd"
echo.
pause
goto MAIN
:INFO
cls
echo ========================= HINWEISE ============================
echo.
echo 1. Die Volumes erscheinen vor der Laufwerksauswahl.
echo 2. Das Windows-Laufwerk wird pro Automatiklauf nur einmal gewÑhlt.
echo 3. X: ist WinPE. Der Recovery-USB-Datentraeger ist gesperrt.
echo 4. BitLocker: das Zielvolume zuvor entsperren.
echo 5. Bei I/O-Fehlern oder Hardwaredefekt zuerst Daten/Image sichern.
echo 6. CHKDSK /f schreibt énderungen ins Dateisystem.
echo 7. DISM /RestoreHealth kann eine passende Quelle benîtigen.
echo 8. SFC nutzt im Automatiklauf das Windows-Laufwerk als Bootpfad.
echo    Bei getrenntem Bootvolume ggf. Einzelmodul nutzen.
echo 9. Bootreparatur nur fÅr UEFI mit manuell geprÅfter ESP.
echo 10. Reboot/Shutdown in WinPE erfolgt Åber WPEUTIL.
echo 11. Menues verwenden OEM-Codepage 850.
echo.
pause
goto MAIN

:AUTO_DIAG
cls
call :ASK_LOGS
call "%MOD%\AutoDiagnose.cmd"
echo.
pause
goto MAIN
:AUTO_REPAIR
cls
call :ASK_LOGS
call "%MOD%\AutoRepair.cmd"
echo.
pause
goto MAIN
:REBOOT
call "%MOD%\PowerActions.cmd" REBOOT
if errorlevel 1 (
    echo Energieaktion fehlgeschlagen.
    pause
    goto MAIN
)
exit /b 0
:POWEROFF
call "%MOD%\PowerActions.cmd" SHUTDOWN
if errorlevel 1 (
    echo Energieaktion fehlgeschlagen.
    pause
    goto MAIN
)
exit /b 0

:ASK_LOGS
set "NOLS_SAVE_LOGS=N"
echo.
echo Sollen Logs auf dem Toolkit-Laufwerk erstellt werden?
echo Bei N nur temporaere Logs; BCD-Backups bleiben erhalten.
set "LOGANSWER="
set /p "LOGANSWER=Logs speichern? [Y/N, Enter=N]: "
if /I "!LOGANSWER!"=="Y" set "NOLS_SAVE_LOGS=Y"
if /I not "!LOGANSWER!"=="Y" if /I not "!LOGANSWER!"=="N" if defined LOGANSWER echo Unbekannte Eingabe - keine Logs.
exit /b 0

:STORAGE_ANALYSIS
call "%MOD%\SpeicherAnalyse.cmd"
echo.
pause
goto MAIN

:BSOD_DRIVERS
call "%MOD%\TreiberBSOD.cmd"
echo.
pause
goto MAIN

:HARDWARE_INVENTORY
cls
call "%MOD%\HardwareInventur.cmd"
echo.
pause
goto MAIN
