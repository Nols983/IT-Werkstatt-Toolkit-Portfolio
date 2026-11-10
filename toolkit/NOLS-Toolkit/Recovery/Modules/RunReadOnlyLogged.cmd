@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem RunReadOnlyLogged.cmd "C:\path\module.cmd" - no interactive commands here.
if "%~1"=="" exit /b 2
set "CMD=%~f1"
if /I not "%NOLS_SAVE_LOGS%"=="Y" (
 call "%CMD%"
 exit /b
)
set "LOGDIR="
call "%~dp0MakeLogDir.cmd" LOGDIR INFO
if errorlevel 1 (
 echo ABBRUCH: Gewuenschter Logordner konnte nicht erstellt werden.
 exit /b 1
)
echo Die Ausgabe wird erfasst und anschliessend angezeigt.
call "%CMD%" >"%LOGDIR%\01_Ausgabe.txt" 2>&1
set "RC=%errorlevel%"
type "%LOGDIR%\01_Ausgabe.txt"
>"%LOGDIR%\00_Ergebnis.txt" echo Einzelpruefung - Rueckgabecode %RC%
echo Protokoll: "%LOGDIR%"
exit /b %RC%
