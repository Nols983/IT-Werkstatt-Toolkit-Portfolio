@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ChooseEsp.cmd RESULT_VAR WINDOWS_LETTER TEMP_FLAG VOLUME_NUMBER
rem WinPE only: user selects one volume, we verify GPT-ESP/FAT32 before assign.
if "%~1"=="" exit /b 2
set "WIN=%~2"
set "USB=%~d0"
set "VOL="
set "ESP="
set "NEWLETTER="
set "PHASE=Vorbereitung"
set "TMPROOT=%TEMP%"
if not defined TMPROOT set "TMPROOT=%SystemRoot%\Temp"
if not exist "!TMPROOT!\" set "TMPROOT=%SystemRoot%\Temp"
if not exist "!TMPROOT!\" goto FAILED
if not exist "%SystemRoot%\System32\diskpart.exe" goto FAILED
set "DP=!TMPROOT!\nols-check-%RANDOM%-%RANDOM%.txt"
set "DP2=!TMPROOT!\nols-assign-%RANDOM%-%RANDOM%.txt"
set "BASE=%~dp0..\Logs"
if /I "%NOLS_SAVE_LOGS%"=="N" set "BASE=!TMPROOT!"
if not exist "!BASE!\" md "!BASE!" >nul 2>&1
if not exist "!BASE!\" set "BASE=!TMPROOT!"
rem ASCII-only names: avoids console/filename encoding problems.
set "OUT=!BASE!\ESP_Check_%RANDOM%_%RANDOM%.log"
set "OUT2=!BASE!\ESP_Assign_%RANDOM%_%RANDOM%.log"
set "FOUND=NEIN"
set "FAT=NEIN"
set "GPTESP=NEIN"
set "BLOCK=NEIN"
set "ROW="

 echo.
 echo ================ EFI-PARTITION WAEHLEN ===================
 echo Windows: !WIN!:\Windows
 echo Bitte die EFI-Volume-Nummer aus DiskPart waehlen.
 echo Achtung: VTOYEFI / Ventoy NICHT waehlen.
 echo.
set "PHASE=Volume-Liste"
call "%~dp0Volumes.cmd"
if errorlevel 1 goto FAILED
set /p "VOL=EFI-Volume-Nr. (Enter = Abbrechen): "
if not defined VOL goto ABORT
set "PHASE=Eingabepruefung"
set "VALIDVOL="
for /L %%N in (0,1,999) do if "!VOL!"=="%%N" set "VALIDVOL=1"
if not defined VALIDVOL (
 echo Bitte nur die Zahl aus der Volume-Liste eingeben.
 goto FAILED
)
set "PHASE=DiskPart-Details"
>"!DP!" echo select volume !VOL!
>>"!DP!" echo detail partition
>>"!DP!" echo list volume
call :WAIT_DISKPART
"%SystemRoot%\System32\diskpart.exe" /s "!DP!" >"!OUT!" 2>&1
set "RC=!errorlevel!"
if not "!RC!"=="0" goto FAILED
if not exist "!OUT!" goto FAILED

rem Robust line parsing: a single complete row, not twelve positional fields.
rem The GPT-ESP GUID is ASCII and independent of the OS display language.
set "PHASE=Partitionsangaben auswerten"
for /f "usebackq delims=" %%L in ("!OUT!") do (
 set "LINE=%%L"
 if not "!LINE:c12a7328-f81f-11d2-ba4b-00a0c93ec93b=!"=="!LINE!" set "GPTESP=JA"
 if not "!LINE:C12A7328-F81F-11D2-BA4B-00A0C93EC93B=!"=="!LINE!" set "GPTESP=JA"
 for /f "tokens=1,2,3" %%A in ("!LINE!") do (
   if "%%A"=="*" if /I "%%B"=="Volume" if "%%C"=="!VOL!" (
      set "FOUND=JA"
      set "ROW=!LINE!"
      if not "!LINE:FAT32=!"=="!LINE!" set "FAT=JA"
      if not "!LINE:VTOYEFI=!"=="!LINE!" set "BLOCK=JA"
      if not "!LINE:Ventoy=!"=="!LINE!" set "BLOCK=JA"
   )
 )
)
echo.
echo Kontrolle von Volume !VOL!:
echo   DiskPart-Auswahl : !FOUND!
echo   FAT32 erkannt   : !FAT!
echo   GPT-ESP erkannt : !GPTESP!
echo   Ventoy-Merkmal  : !BLOCK!
if defined ROW echo   Volume-Zeile     : !ROW!
if /I not "!FOUND!"=="JA" goto FAILED
if /I not "!FAT!"=="JA" goto FAILED
if /I not "!GPTESP!"=="JA" goto FAILED
if /I "!BLOCK!"=="JA" goto FAILED
set "PHASE=USB-Datentraeger schuetzen"
call "%~dp0WriteTargetGuard.cmd" "!VOL!" VOLUME
if errorlevel 1 goto FAILED
rem A 32 MB VTOYEFI ESP can also have the GPT-ESP GUID; do not rely on GPT alone.
rem Extra guard prevents accidentally selecting currently booted USB volume.
if /I "!VOL!"=="" goto FAILED
set "PHASE=Laufwerksbuchstabe ermitteln"
set "EXISTING="
for /f "tokens=1,2,3,4" %%A in ("!ROW!") do (
 if "%%A"=="*" if /I "%%B"=="Volume" if "%%C"=="!VOL!" (
   for %%K in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
     if /I "%%D"=="%%K" set "EXISTING=%%K"
   )
 )
)
if defined EXISTING (
 set "ESP=!EXISTING!"
 echo Bereits zugewiesener Buchstabe: !ESP!:
) else (
 for %%K in (S R Q P T U V W Y Z) do if not defined ESP if not exist "%%K:\" set "ESP=%%K"
 if not defined ESP goto FAILED
 echo EFI-Volume !VOL! bekommt voruebergehend !ESP!:.
 set "PHASE=DiskPart-Buchstabe zuweisen"
 set "ASSIGN_TRIED=1"
 >"!DP2!" echo select volume !VOL!
 >>"!DP2!" echo assign letter=!ESP!
 >>"!DP2!" echo detail partition
 >>"!DP2!" echo list volume
 call :WAIT_DISKPART
 "%SystemRoot%\System32\diskpart.exe" /s "!DP2!" >"!OUT2!" 2>&1
 set "RC=!errorlevel!"
 if not "!RC!"=="0" goto FAILED
 rem Confirm selected volume AND the newly assigned letter using the full row.
 set "ASSIGNED=NEIN"
 set "ASSIGNED_GUID=NEIN"
 for /f "usebackq delims=" %%L in ("!OUT2!") do (
   set "LINE=%%L"
   if not "!LINE:c12a7328-f81f-11d2-ba4b-00a0c93ec93b=!"=="!LINE!" set "ASSIGNED_GUID=JA"
   if not "!LINE:C12A7328-F81F-11D2-BA4B-00A0C93EC93B=!"=="!LINE!" set "ASSIGNED_GUID=JA"
   for /f "tokens=1,2,3,4" %%A in ("!LINE!") do (
     if "%%A"=="*" if /I "%%B"=="Volume" if "%%C"=="!VOL!" if /I "%%D"=="!ESP!" set "ASSIGNED=JA"
   )
 )
 echo   Zuordnung zu Volume !VOL!: !ASSIGNED!; GPT-ESP: !ASSIGNED_GUID!
 if /I not "!ASSIGNED!"=="JA" goto FAILED
 if /I not "!ASSIGNED_GUID!"=="JA" goto FAILED
 set "NEWLETTER=1"
)
set "PHASE=EFI-Zugriff"
if /I "!ESP!"=="!WIN!" goto FAILED
if /I "!ESP!:"=="!USB!" goto FAILED
if not exist "!ESP!:\" goto FAILED
if exist "!ESP!:\ventoy\ventoy.json" goto FAILED
if exist "!ESP!:\ENROLL_THIS_KEY_IN_MOKMANAGER.cer" goto FAILED
if not exist "!ESP!:\EFI\" echo HINWEIS: Kein EFI-Verzeichnis; BCD kann fehlen.
echo [OK] EFI-Volume !VOL! ist unter !ESP!: erreichbar.
call :CLEAN
endlocal & set "%~1=%ESP%" & if not "%~3"=="" set "%~3=%NEWLETTER%" & if not "%~4"=="" set "%~4=%VOL%" & exit /b 0
:ABORT
echo Abgebrochen.
call :CLEAN
exit /b 2
:FAILED
echo.
echo ABBRUCH in Phase: !PHASE!
echo Volume !VOL!: Auswahl !FOUND!, FAT32 !FAT!, GPT-ESP !GPTESP!
echo Ventoy-Merkmal: !BLOCK!
if defined ROW echo   Zeile: !ROW!
if defined OUT if exist "!OUT!" echo   Pruefprotokoll: "!OUT!"
if defined OUT2 if exist "!OUT2!" (
 echo   Zuweisungsprotokoll: "!OUT2!"
 type "!OUT2!"
)
rem ReleaseEsp performs a separate GUID/volume/letter check before any removal.
if defined ASSIGN_TRIED if defined ESP if defined VOL if exist "!ESP!:\" (
 echo Versuche, eigenen temporaeren Buchstaben zu entfernen ...
 call "%~dp0ReleaseEsp.cmd" !VOL! !ESP!
)
if /I "!PHASE!"=="DiskPart-Buchstabe zuweisen" (
 echo HINWEIS: Falls bereits !ESP!: zugewiesen wurde, bitte Zuordnung
 echo vor weiteren Reparaturen manuell ueberpruefen.
)
call :CLEAN
exit /b 1
:CLEAN
for %%F in ("!DP!" "!DP2!") do if exist "%%~F" del /q "%%~F" >nul 2>&1
if /I "%NOLS_SAVE_LOGS%"=="N" (
 for %%F in ("!OUT!" "!OUT2!") do if exist "%%~F" del /q "%%~F" >nul 2>&1
)
exit /b 0
:WAIT_DISKPART
if exist "%SystemRoot%\System32\timeout.exe" "%SystemRoot%\System32\timeout.exe" /t 15 /nobreak >nul 2>&1
exit /b 0
