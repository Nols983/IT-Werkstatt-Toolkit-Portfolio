@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ReleaseEsp.cmd VOLNUM LETTER: call only if ChooseEsp reported TEMP_FLAG=1.
set "VOL=%~1"
set "LETTER=%~2"
set "VALIDVOL="
for /L %%N in (0,1,999) do if "!VOL!"=="%%N" set "VALIDVOL=1"
if not defined VALIDVOL exit /b 2
set "VALIDLETTER="
for %%L in (S R Q P T U V W Y Z) do if /I "!LETTER!"=="%%L" set "VALIDLETTER=1"
if not defined VALIDLETTER exit /b 2
if /I "!LETTER!:"=="%~d0" exit /b 2
if not exist "!LETTER!:\" (
 echo HINWEIS: !LETTER!: ist bereits nicht mehr erreichbar.
 exit /b 0
)
set "TEMPBASE=%TEMP%"
if not defined TEMPBASE set "TEMPBASE=%SystemRoot%\Temp"
if not exist "!TEMPBASE!\" set "TEMPBASE=%SystemRoot%\Temp"
if not exist "!TEMPBASE!\" exit /b 1
set "DP=!TEMPBASE!\nols-release-%RANDOM%-%RANDOM%.txt"
set "LOG=!TEMPBASE!\nols-release-%RANDOM%-%RANDOM%.log"
>"!DP!" echo select volume !VOL!
>>"!DP!" echo detail partition
>>"!DP!" echo list volume
"%SystemRoot%\System32\diskpart.exe" /s "!DP!" >"!LOG!" 2>&1
if errorlevel 1 goto FAILED
set "GPTESP=NEIN"
set "MATCH=NEIN"
for /f "usebackq delims=" %%L in ("!LOG!") do (
 set "LINE=%%L"
 if not "!LINE:c12a7328-f81f-11d2-ba4b-00a0c93ec93b=!"=="!LINE!" set "GPTESP=JA"
 if not "!LINE:C12A7328-F81F-11D2-BA4B-00A0C93EC93B=!"=="!LINE!" set "GPTESP=JA"
 for /f "tokens=1,2,3,4" %%A in ("!LINE!") do (
  if "%%A"=="*" if /I "%%B"=="Volume" if "%%C"=="!VOL!" if /I "%%D"=="!LETTER!" set "MATCH=JA"
 )
)
if /I not "!GPTESP!"=="JA" goto FAILED
if /I not "!MATCH!"=="JA" goto FAILED
>"!DP!" echo select volume !VOL!
>>"!DP!" echo remove letter=!LETTER!
if exist "%SystemRoot%\System32\timeout.exe" "%SystemRoot%\System32\timeout.exe" /t 15 /nobreak >nul 2>&1
"%SystemRoot%\System32\diskpart.exe" /s "!DP!" >"!LOG!" 2>&1
if errorlevel 1 goto FAILED
if exist "!LETTER!:\" goto FAILED
echo [OK] Temporaeren EFI-Buchstaben !LETTER!: entfernt.
call :CLEAN
exit /b 0
:FAILED
echo WARNUNG: !LETTER!: konnte nicht sicher von Volume !VOL! geloest werden.
echo Bitte 'diskpart', 'list volume' kontrollieren; es wurde nichts geloescht.
if exist "!LOG!" type "!LOG!"
call :CLEAN
exit /b 1
:CLEAN
for %%F in ("!DP!" "!LOG!") do if exist "%%~F" del /q "%%~F" >nul 2>&1
exit /b 0
