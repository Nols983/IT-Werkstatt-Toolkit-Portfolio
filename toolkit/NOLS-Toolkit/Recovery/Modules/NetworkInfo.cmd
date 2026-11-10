@echo off
setlocal EnableExtensions
echo.
echo ===== NETZWERK / NUR STATUS =====
echo WinPE/WinRE hat m”glicherweise noch keinen initialisierten Netzwerkstack.
if not exist "%SystemRoot%\System32\ipconfig.exe" (
    echo ipconfig ist in dieser Umgebung nicht vorhanden.
) else (
    ipconfig.exe /all
)
echo.
if not exist "%SystemRoot%\System32\route.exe" (
    echo route ist in dieser Umgebung nicht vorhanden.
) else (
    route.exe print
)
echo Kein Netzwerk wird automatisch initialisiert oder konfiguriert.
exit /b 0
