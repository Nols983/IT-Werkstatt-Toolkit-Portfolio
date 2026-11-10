@echo off
setlocal
cd /d "%~dp0"
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy RemoteSigned -File "%~dp0Launcher.ps1"
if errorlevel 1 (
 echo.
 echo Der Launcher konnte nicht gestartet werden.
 echo Sicherheitsrichtlinien werden NICHT automatisch umgangen.
 echo Lies README.txt fuer die sichere Fehleranalyse.
 pause
)
