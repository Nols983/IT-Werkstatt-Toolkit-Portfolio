@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Bootdiagnose: keine BCD/EFI-Žnderung. AUTO <WindowsBuchstabe> <Logdir>
set "AUTO=0"
if /I "%~1"=="AUTO" set "AUTO=1"
if "!AUTO!"=="1" (
    set "WIN=%~2"
    set "LOGDIR=%~3"
) else (
    set "WIN="
    call "%~dp0ChooseDrive.cmd" WIN WINDOWS
    if errorlevel 1 exit /b 1
)
if not defined WIN exit /b 1
if not exist "!WIN!:\Windows\System32\Config\SYSTEM" exit /b 1
if not defined LOGDIR (
 if /I "%NOLS_SAVE_LOGS%"=="N" (
    set "LOGDIR=%TEMP%\NOLS-Toolkit-Temp\BOOT_%RANDOM%_%RANDOM%"
 ) else (
    set "LOGDIR=%~dp0..\Logs\BOOT_%RANDOM%_%RANDOM%"
 )
)
if /I "%NOLS_SAVE_LOGS%"=="N" if not exist "%TEMP%\NOLS-Toolkit-Temp\" md "%TEMP%\NOLS-Toolkit-Temp" >nul 2>&1
if not exist "!LOGDIR!\" md "!LOGDIR!" >nul 2>&1
if not exist "!LOGDIR!\" (
 echo ABBRUCH: Kein Logverzeichnis auf dem Toolkit verfgbar.
 exit /b 1
)
set "REPORT=!LOGDIR!\50_BOOT_Zustand.txt"
>"!REPORT!" echo IT-WERKSTATT BOOTDIAGNOSE v2.4.2 - NUR LESEN
>>"!REPORT!" echo Windows: !WIN!:\Windows
>>"!REPORT!" echo.
echo.
echo ================== BOOTDIAGNOSE ============================
echo Windows: !WIN!:\Windows
echo Firmware des aktuell gestarteten WinPE:
if exist "%SystemRoot%\System32\wpeutil.exe" wpeutil.exe UpdateBootInfo >nul 2>&1
set "FW=UNBEKANNT"
for /f "tokens=1,2,3" %%A in ('reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control" /v PEFirmwareType 2^>nul') do if /I "%%A"=="PEFirmwareType" if /I "%%B"=="REG_DWORD" set "FW=%%C"
echo   !FW! ^(0x2 = UEFI, 0x1 = Legacy BIOS^)
>>"!REPORT!" echo WinPE-Firmware: !FW!
>>"!REPORT!" echo Achtung: Dies ist der Startmodus von WinPE, NICHT ein GPT-Beweis.
if exist "%SystemRoot%\System32\manage-bde.exe" (
    echo.
    echo BitLocker-Status des Windows-Volumes:
    "%SystemRoot%\System32\manage-bde.exe" -status !WIN!: >"!LOGDIR!\51_BitLocker.txt" 2>&1
    type "!LOGDIR!\51_BitLocker.txt"
    >>"!REPORT!" echo BitLocker-Protokoll: 51_BitLocker.txt
) else (
    >>"!REPORT!" echo BitLocker-Tool nicht verfgbar.
)
if exist "%SystemRoot%\System32\bcdedit.exe" (
    "%SystemRoot%\System32\bcdedit.exe" /enum firmware /v >"!LOGDIR!\52_Firmware_Eintraege.txt" 2>&1
    >>"!REPORT!" echo Firmware-Eintr„ge: 52_Firmware_Eintraege.txt
)
if "!AUTO!"=="1" (
    >>"!REPORT!" echo Offline-BCD: NICHT geprft, da keine ESP ausgew„hlt wurde.
    goto FINISH
)
echo.
echo Jetzt EFI-Volume anhand der DiskPart-Liste ausw„hlen.
echo Ein fehlender Laufwerksbuchstabe wird vorbergehend vergeben.
set "ESP="
set "ESP_TEMP="
set "ESP_NUMBER="
call "%~dp0ChooseEsp.cmd" ESP !WIN! ESP_TEMP ESP_NUMBER
if errorlevel 1 (
    >>"!REPORT!" echo Offline-BCD: EFI-Auswahl abgebrochen oder fehlgeschlagen.
    goto FINISH
)
set "STORE=!ESP!:\EFI\Microsoft\Boot\BCD"
if not exist "!STORE!" (
    echo BCD-Datei fehlt: !STORE!
    >>"!REPORT!" echo BCD-Datei fehlt: !STORE!
    goto FINISH
)
if not exist "%SystemRoot%\System32\bcdedit.exe" goto FINISH
"%SystemRoot%\System32\bcdedit.exe" /store "!STORE!" /enum all /v >"!LOGDIR!\53_Offline_BCD.txt" 2>&1
set "BCD_RC=!errorlevel!"
type "!LOGDIR!\53_Offline_BCD.txt"
>>"!REPORT!" echo Offline-BCD: !STORE! - BCDEdit-RC !BCD_RC!
>>"!REPORT!" echo Offline-BCD-Protokoll: 53_Offline_BCD.txt
:FINISH
if defined ESP_TEMP (
 call "%~dp0ReleaseEsp.cmd" !ESP_NUMBER! !ESP!
 if errorlevel 1 >>"!REPORT!" echo WARNUNG: Tempor„rer ESP-Buchstabe konnte nicht entfernt werden.
)
echo.
echo ===================== ZUSAMMENFASSUNG =========================
type "!REPORT!"
echo.
if /I "%NOLS_SAVE_LOGS%"=="N" (
 echo Berichte wurden nur temporaer fuer diese Sitzung erzeugt.
) else (
 echo Weitere Daten: "!LOGDIR!"
)
echo Eine Datei/Eintrag im BCD beweist keinen erfolgreichen Windows-Start.
if /I "%NOLS_SAVE_LOGS%"=="N" if "!AUTO!"=="0" (
 rd /s /q "!LOGDIR!" >nul 2>&1
 echo Keine dauerhaften Toolkit-Logs gespeichert.
)
exit /b 0
