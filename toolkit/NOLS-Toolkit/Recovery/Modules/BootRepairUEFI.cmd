@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem UEFI-Bootreparatur: nur manuell gew„hlte GPT-ESP, mit BCD-Sicherung.
rem Keine Formatierung, keine Partitionsaenderung, kein bootrec.
set "RESULT=1"
set "ESP="
set "ESP_TEMP="
set "ESP_NUMBER="
reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control\MiniNT" >nul 2>&1
if not errorlevel 1 goto PE_OK
if /I "%SystemDrive%"=="X:" goto PE_OK
echo ABBRUCH: Bitte nur aus WinPE/WinRE ausfhren.
exit /b 1
:PE_OK
if exist "%SystemRoot%\System32\wpeutil.exe" wpeutil.exe UpdateBootInfo >nul 2>&1
set "FW=UNBEKANNT"
for /f "tokens=1,2,3" %%A in ('reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control" /v PEFirmwareType 2^>nul') do if /I "%%A"=="PEFirmwareType" if /I "%%B"=="REG_DWORD" set "FW=%%C"
if /I not "!FW!"=="0x2" (
 echo ABBRUCH: Nur UEFI wird untersttzt. WinPE-Firmware: !FW!
 exit /b 1
)
if not exist "%SystemRoot%\System32\bcdboot.exe" (
 echo ABBRUCH: BCDBoot fehlt in WinPE.
 exit /b 1
)
echo.
echo ================== UEFI-BOOTREPARATUR ====================
echo BCDBoot kann Bootdateien und BCD ver„ndern.
echo Prfe Windows und EFI auf demselben Ziel-PC.
echo Bei Dual-Boot und BitLocker besonders vorsichtig sein.
echo.
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
call "%~dp0WriteTargetGuard.cmd" !WIN! DRIVE
if errorlevel 1 exit /b 1
if not exist "!WIN!:\Windows\System32\Config\BCD-Template" (
 echo ABBRUCH: Windows-BCD-Template fehlt.
 exit /b 1
)
echo.
echo BitLocker-Status der Windows-Partition:
if exist "%SystemRoot%\System32\manage-bde.exe" "%SystemRoot%\System32\manage-bde.exe" -status !WIN!:
echo.
echo Jetzt die EFI-Volume-Nr. aus DiskPart ausw„hlen.
 rem Bei Y: nur die ESP-Logs DIESES Durchlaufs am Ende ins Reparaturverzeichnis verschieben.
 set "ESP_LOGBASE=%~dp0..\Logs"
 set "ESP_SNAPSHOT="
 if /I not "%NOLS_SAVE_LOGS%"=="N" (
   set "ESP_SNAPSHOT=%TEMP%\NOLS-ESP-Pre-%RANDOM%-%RANDOM%"
   if not exist "!ESP_SNAPSHOT!\" md "!ESP_SNAPSHOT!" >nul 2>&1
   if not exist "!ESP_SNAPSHOT!\" (
     echo ABBRUCH: Temporaeres Log-Inventar kann nicht angelegt werden.
     exit /b 1
   )
   for %%F in ("!ESP_LOGBASE!\ESP_Check_*.log" "!ESP_LOGBASE!\ESP_Assign_*.log") do (
     if exist "%%~fF" >"!ESP_SNAPSHOT!\%%~nxF" echo vorhanden
   )
 )
 call "%~dp0ChooseEsp.cmd" ESP !WIN! ESP_TEMP ESP_NUMBER
 if errorlevel 1 (
   if defined ESP_SNAPSHOT if exist "!ESP_SNAPSHOT!\" rd /s /q "!ESP_SNAPSHOT!" >nul 2>&1
   exit /b 1
 )
if /I "!ESP!"=="!WIN!" goto DONE
if /I "!ESP!:"=="%~d0" goto DONE
set "LOGBASE=%~dp0..\Logs"
if /I "%NOLS_SAVE_LOGS%"=="N" set "LOGBASE=%TEMP%\NOLS-Toolkit-Temp"
if not exist "!LOGBASE!\" md "!LOGBASE!" >nul 2>&1
set "LOGDIR=!LOGBASE!\BOOT_REPAIR_%RANDOM%_%RANDOM%"
set "BCD_BACKUP_DIR="
if exist "!LOGDIR!\" goto DONE
md "!LOGDIR!" >nul 2>&1
if not exist "!LOGDIR!\" (
 echo ABBRUCH: USB-Logverzeichnis nicht schreibbar.
 goto DONE
)
>"!LOGDIR!\WRITE_TEST.tmp" echo Test
if errorlevel 1 goto DONE
del /q "!LOGDIR!\WRITE_TEST.tmp" >nul 2>&1
set "STORE=!ESP!:\EFI\Microsoft\Boot\BCD"
>"!LOGDIR!\00_Ablauf.txt" echo IT-WERKSTATT UEFI-Bootreparatur v2.4.2
>>"!LOGDIR!\00_Ablauf.txt" echo Windows: !WIN!:\Windows
>>"!LOGDIR!\00_Ablauf.txt" echo EFI-Volume: !ESP_NUMBER! - !ESP!:
>>"!LOGDIR!\00_Ablauf.txt" echo WinPE-Firmware: !FW!
>>"!LOGDIR!\00_Ablauf.txt" echo Befehl: bcdboot !WIN!:\Windows /s !ESP!: /f UEFI
if exist "!STORE!" (
 copy /B /Y "!STORE!" "!LOGDIR!\BCD_VORHER.bak" >nul
 if errorlevel 1 goto BACKUP_FAIL
 if not exist "!LOGDIR!\BCD_VORHER.bak" goto BACKUP_FAIL
 for %%F in ("!LOGDIR!\BCD_VORHER.bak") do if %%~zF EQU 0 goto BACKUP_FAIL
 if exist "%SystemRoot%\System32\fc.exe" (
   "%SystemRoot%\System32\fc.exe" /B "!STORE!" "!LOGDIR!\BCD_VORHER.bak" >nul 2>&1
   if errorlevel 1 goto BACKUP_FAIL
 )
 rem Auch ohne Protokollierung ist eine DAUERHAFTE BCD-Sicherung auf dem Toolkit-Laufwerk Pflicht.
 if /I "%NOLS_SAVE_LOGS%"=="N" (
   set "BCD_BACKUP_DIR=%~dp0..\Backups\BCD_%RANDOM%_%RANDOM%"
   md "!BCD_BACKUP_DIR!" >nul 2>&1
   if not exist "!BCD_BACKUP_DIR!\" goto BACKUP_FAIL
   copy /B /Y "!LOGDIR!\BCD_VORHER.bak" "!BCD_BACKUP_DIR!\BCD_VORHER.bak" >nul
   if errorlevel 1 goto BACKUP_FAIL
   if not exist "!BCD_BACKUP_DIR!\BCD_VORHER.bak" goto BACKUP_FAIL
   for %%F in ("!BCD_BACKUP_DIR!\BCD_VORHER.bak") do if %%~zF EQU 0 goto BACKUP_FAIL
   if exist "%SystemRoot%\System32\fc.exe" (
      "%SystemRoot%\System32\fc.exe" /B "!STORE!" "!BCD_BACKUP_DIR!\BCD_VORHER.bak" >nul 2>&1
      if errorlevel 1 goto BACKUP_FAIL
   )
   echo [OK] BCD-Pflichtsicherung: !BCD_BACKUP_DIR!
 ) else (
   echo [OK] Vorhandene BCD gesichert auf dem Toolkit-Laufwerk.
 )
 if exist "%SystemRoot%\System32\bcdedit.exe" "%SystemRoot%\System32\bcdedit.exe" /store "!STORE!" /enum all /v >"!LOGDIR!\BCD_VORHER.txt" 2>&1
) else (
 echo HINWEIS: Keine vorhandene BCD. Eine neue kann erstellt werden.
 >>"!LOGDIR!\00_Ablauf.txt" echo Vorhandene BCD fehlt.
)
echo.
echo ================== REPARATUR-ZIEL ========================
echo Windows:   !WIN!:\Windows
echo EFI:       Volume !ESP_NUMBER! = !ESP!: - GPT-ESP / FAT32
if /I not "%NOLS_SAVE_LOGS%"=="N" echo Protokoll: "!LOGDIR!"
echo.
echo Geplanter Befehl: bcdboot !WIN!:\Windows /s !ESP!: /f UEFI
echo Hinweis: Mit /s wird KEIN neuer UEFI-Firmwareeintrag erzeugt.
echo Mehrfach-Bootsysteme k”nnen beeinflusst werden.
echo Nur fortsetzen, wenn Windows und ESP zum SELBEN PC gehoeren.
echo.
set "GO="
set /p "GO=Bootdateien jetzt ver„ndern? (Y/N): "
if /I not "!GO!"=="Y" (
 echo Ohne Reparatur beendet.
 >>"!LOGDIR!\00_Ablauf.txt" echo Vom Nutzer abgebrochen.
 set "RESULT=0"
 goto DONE
)
"%SystemRoot%\System32\bcdboot.exe" "!WIN!:\Windows" /s !ESP!: /f UEFI >"!LOGDIR!\BCDBoot.txt" 2>&1
set "RC=!errorlevel!"
type "!LOGDIR!\BCDBoot.txt"
>>"!LOGDIR!\00_Ablauf.txt" echo BCDBoot-Rckgabecode: !RC!
if not "!RC!"=="0" (
 echo FEHLER: BCDBoot schlug fehl. Protokoll prfen.
 goto DONE
)
if not exist "!STORE!" (
 echo WARNUNG: BCD nach Reparatur nicht gefunden.
 goto DONE
)
if exist "%SystemRoot%\System32\bcdedit.exe" (
 "%SystemRoot%\System32\bcdedit.exe" /store "!STORE!" /enum all /v >"!LOGDIR!\BCD_NACHHER.txt" 2>&1
 if errorlevel 1 echo WARNUNG: Die BCD-Nachpruefung ist fehlgeschlagen.
)
echo [OK] BCDBoot wurde ausgefhrt. Kein automatischer Neustart.
if /I "%NOLS_SAVE_LOGS%"=="N" (
 echo Keine dauerhaften Logs. BCD-Sicherung: !BCD_BACKUP_DIR!
) else (
 echo Protokolle und Sicherung: "!LOGDIR!"
)
set "RESULT=0"
goto DONE
:BACKUP_FAIL
echo ABBRUCH: BCD-Sicherung auf dem Toolkit-Laufwerk fehlgeschlagen.
echo Es wurden keine Bootdateien durch dieses Modul ver„ndert.
:DONE
 rem Keine alten ESP-Logs verschieben: Abgleich mit Inventar von VOR ChooseEsp.
 if /I not "%NOLS_SAVE_LOGS%"=="N" if defined ESP_SNAPSHOT if defined LOGDIR if exist "!LOGDIR!\" (
   for %%F in ("!ESP_LOGBASE!\ESP_Check_*.log" "!ESP_LOGBASE!\ESP_Assign_*.log") do (
     if exist "%%~fF" if not exist "!ESP_SNAPSHOT!\%%~nxF" (
       if not exist "!LOGDIR!\%%~nxF" (
         move "%%~fF" "!LOGDIR!\" >nul
         if errorlevel 1 echo WARNUNG: ESP-Log konnte nicht einsortiert werden: %%~nxF
       ) else (
         echo WARNUNG: ESP-Log existiert im Ziel bereits: %%~nxF
       )
     )
   )
 )
 if defined ESP_SNAPSHOT if exist "!ESP_SNAPSHOT!\" rd /s /q "!ESP_SNAPSHOT!" >nul 2>&1
 if /I "%NOLS_SAVE_LOGS%"=="N" if defined LOGDIR if exist "!LOGDIR!\" rd /s /q "!LOGDIR!" >nul 2>&1
if defined ESP_TEMP (
 call "%~dp0ReleaseEsp.cmd" !ESP_NUMBER! !ESP!
 if errorlevel 1 echo WARNUNG: Tempor„rer EFI-Buchstabe blieb evtl. zugewiesen.
)
exit /b !RESULT!
