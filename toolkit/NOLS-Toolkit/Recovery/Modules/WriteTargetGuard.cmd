@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem IT-Werkstatt v2.4.2 RC: fail-closed physische Datentraegerpruefung.
rem call WriteTargetGuard.cmd C [DRIVE]   oder: 2 VOLUME
rem Nur DiskPart SELECT und DETAIL - keine Aenderungen.
set "TARGET=%~1"
set "MODE=%~2"
if not defined MODE set "MODE=DRIVE"
if not defined TARGET goto FAIL
if not exist "%SystemRoot%\System32\diskpart.exe" goto FAIL
if /I not "!MODE!"=="DRIVE" if /I not "!MODE!"=="VOLUME" goto FAIL
set "KIT=%~d0"
if not exist "!KIT!\" goto FAIL
if /I "!MODE!"=="DRIVE" (
 if /I "!TARGET!"=="X" goto FAIL
 if /I "!TARGET!:"=="!KIT!" goto FAIL
 set "VALID=N"
 for %%L in (A B C D E F G H I J K L M N O P Q R S T U V W Y Z) do if /I "!TARGET!"=="%%L" set "VALID=Y"
 if /I not "!VALID!"=="Y" goto FAIL
 if not exist "!TARGET!:\" goto FAIL
) else (
 set "VALID=N"
 for /L %%N in (0,1,999) do if "!TARGET!"=="%%N" set "VALID=Y"
 if /I not "!VALID!"=="Y" goto FAIL
)
call :DISK_OF "!KIT:~0,1!" KIT_DISK
if errorlevel 1 goto FAIL
call :DISK_OF "!TARGET!" TARGET_DISK
if errorlevel 1 goto FAIL
echo.
echo ============== REPARATUR-ZIELPRUEFUNG ===============
echo Toolkit-USB:   !KIT! / physischer Datentraeger !KIT_DISK!
echo Ziel:          !TARGET! / physischer Datentraeger !TARGET_DISK!
if "!KIT_DISK!"=="!TARGET_DISK!" (
 echo ABBRUCH: Ziel liegt auf demselben physischen Datentraeger.
 echo Dies schuetzt auch weitere Partitionen des Recovery-USB.
 exit /b 1
)
echo [OK] Ziel liegt nicht auf dem Toolkit-Datentraeger.
echo Pruefe trotzdem Volume, Label und BitLocker vor der Reparatur.
exit /b 0
:DISK_OF
set "SEL=%~1"
set "DISK_ID="
if not defined TEMP set "TEMP=%SystemRoot%\Temp"
set "SCRIPT=%TEMP%\ITW_GUARD_%RANDOM%_%RANDOM%.txt"
set "OUTPUT=%SCRIPT%.out"
>"!SCRIPT!" echo select volume !SEL!
>>"!SCRIPT!" echo detail volume
"%SystemRoot%\System32\diskpart.exe" /s "!SCRIPT!" >"!OUTPUT!" 2>&1
set "STATUS=!errorlevel!"
if "!STATUS!"=="0" (
 for /f "usebackq tokens=1,2,3" %%A in ("!OUTPUT!") do (
   if /I "%%A"=="Disk" call :CONSIDER "%%B"
   if /I "%%A"=="Datentr„ger" call :CONSIDER "%%B"
   if "%%A"=="*" if /I "%%B"=="Disk" call :CONSIDER "%%C"
   if "%%A"=="*" if /I "%%B"=="Datentr„ger" call :CONSIDER "%%C"
 )
)
if exist "!SCRIPT!" del /q "!SCRIPT!" >nul 2>&1
if exist "!OUTPUT!" del /q "!OUTPUT!" >nul 2>&1
if not "!STATUS!"=="0" exit /b 1
if not defined DISK_ID exit /b 1
if /I "!DISK_ID!"=="UNSICHER" exit /b 1
set "%~2=!DISK_ID!"
exit /b 0
:CONSIDER
set "CAND=%~1"
if not defined CAND exit /b 0
for /f "delims=0123456789" %%Z in ("!CAND!") do set "CAND="
if not defined CAND exit /b 0
if /I "!DISK_ID!"=="UNSICHER" exit /b 0
if not defined DISK_ID set "DISK_ID=!CAND!"
if not "!DISK_ID!"=="!CAND!" set "DISK_ID=UNSICHER"
exit /b 0
:FAIL
echo.
echo ABBRUCH: Das Ziel kann nicht sicher freigegeben werden.
echo Keine Reparatur ohne eindeutige physische Datentraegerzuordnung.
echo Bitte DiskPart-Daten und USB-Anbindung manuell pruefen.
exit /b 1
