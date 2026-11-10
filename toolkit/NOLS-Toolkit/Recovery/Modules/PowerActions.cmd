@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Nur fuer Windows PE/RE. Keine Ausweichbefehle mit shutdown.exe/poweroff.
set "ACTION=%~1"
if /I not "%ACTION%"=="REBOOT" if /I not "%ACTION%"=="SHUTDOWN" (
  echo FEHLER: Unbekannte Aktion. Erlaubt: REBOOT oder SHUTDOWN.
  exit /b 2
)
rem Recovery-Modus pruefen, damit START-RECOVERY.cmd unter Desktop-Windows
rem nicht versehentlich eine andere Aktion ausloest.
reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control\MiniNT" >nul 2>&1
if not errorlevel 1 goto in_pe
if /I "%SystemDrive%"=="X:" goto in_pe
echo ABBRUCH: Keine Windows-PE-/RE-Umgebung erkannt.
exit /b 1

:in_pe
set "WPE=%SystemRoot%\System32\wpeutil.exe"
if not exist "%WPE%" (
  echo FEHLER: WPEUTIL.EXE ist nicht verfÅgbar.
  echo In dieser Umgebung wird kein Ersatzbefehl ausgefÅhrt.
  exit /b 1
)
echo.
if /I "%ACTION%"=="REBOOT" goto reboot
if /I "%ACTION%"=="SHUTDOWN" goto shutdown
exit /b 2

:reboot
echo ===== IT-WERKSTATT RECOVERY: NEUSTART =====
echo Laufende Diagnosen sollten vorher beendet sein.
echo Speichere offene Dateien und hÑnge externe DatentrÑger sauber aus.
echo.
"%WPE%" Reboot
set "RC=%errorlevel%"
echo WPEUTIL RÅckgabecode: %RC%
exit /b %RC%

:shutdown
echo ===== IT-WERKSTATT RECOVERY: HERUNTERFAHREN =====
echo Laufende Diagnosen sollten vorher beendet sein.
echo Speichere offene Dateien und hÑnge externe DatentrÑger sauber aus.
echo.
"%WPE%" Shutdown
set "RC=%errorlevel%"
echo WPEUTIL RÅckgabecode: %RC%
exit /b %RC%
