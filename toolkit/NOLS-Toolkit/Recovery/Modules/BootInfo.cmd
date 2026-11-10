@echo off
setlocal EnableExtensions
echo.
echo ===== AKTIVER BCD STORE (NUR LESEN) =====
echo ACHTUNG: Im Windows-Setup kann der aktive BCD-Store nur
 echo          das gestartete WinPE/Installationsmedium beschreiben!
echo NICHT als eindeutige Aussage Åber das Offline-Windows verstehen.
echo Die EFI-Partition wird NICHT eingebunden oder verÑndert.
echo.
if not exist "%SystemRoot%\System32\bcdedit.exe" (
    echo bcdedit ist in dieser Umgebung nicht verfÅgbar.
    exit /b 1
)
bcdedit.exe /enum all
exit /b %errorlevel%
