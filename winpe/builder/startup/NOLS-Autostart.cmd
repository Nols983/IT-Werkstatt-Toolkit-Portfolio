@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 850 >nul 2>&1
title NOLS Recovery OS v1.0

:SEARCH
cls
echo ===============================================================
echo                    NOLS RECOVERY OS v1.0
echo ===============================================================
echo.
echo Suche vorhandenes NOLS-Toolkit auf Laufwerken ...
set "MATCHES=0"
set "TOOLROOT="
for %%L in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if exist "%%L:\NOLS-Toolkit\START-RECOVERY.cmd" if exist "%%L:\NOLS-Toolkit\Recovery\Recovery-Launcher.cmd" if exist "%%L:\NOLS-Toolkit\Recovery\Modules\ChooseDrive.cmd" (
        set /a MATCHES+=1 >nul
        set "TOOLROOT=%%L:\NOLS-Toolkit"
        echo [GEFUNDEN] %%L:\NOLS-Toolkit
    )
)
if "!MATCHES!"=="1" goto :START
if "!MATCHES!"=="0" echo [HINWEIS] Kein vollstaendiges Toolkit gefunden.
if not "!MATCHES!"=="0" echo [HINWEIS] Mehrere Toolkits gefunden - bitte Laufwerk waehlen.

:MENU
echo.
echo [R] Laufwerke erneut durchsuchen
echo [M] Laufwerksbuchstaben manuell waehlen
echo [C] Normale WinPE-CMD oeffnen
echo.
set "ANS="
set /p "ANS=Auswahl: "
if /I "!ANS!"=="R" goto :SEARCH
if /I "!ANS!"=="M" goto :MANUAL
if /I "!ANS!"=="C" goto :CONSOLE
goto :MENU

:MANUAL
echo.
set "DRIVE="
set /p "DRIVE=Toolkit-Laufwerksbuchstabe (z.B. E): "
for %%L in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if /I "!DRIVE!"=="%%L" (
        set "TOOLROOT=%%L:\NOLS-Toolkit"
        if exist "!TOOLROOT!\START-RECOVERY.cmd" if exist "!TOOLROOT!\Recovery\Recovery-Launcher.cmd" if exist "!TOOLROOT!\Recovery\Modules\ChooseDrive.cmd" goto :START
    )
)
echo [FEHLER] Ungueltiger Buchstabe oder Toolkit nicht vollstaendig.
goto :MENU

:START
cls
echo ===============================================================
echo NOLS Toolkit gefunden: !TOOLROOT!
echo ===============================================================
echo.
call X:\NOLS\NOLS-Preflight.cmd
echo.
echo Starte vorhandenes NOLS IT Toolkit ...
echo.
pushd "!TOOLROOT!"
if errorlevel 1 (
    echo [FEHLER] Laufwerk konnte nicht geoeffnet werden.
    goto :CONSOLE
)
call "!TOOLROOT!\START-RECOVERY.cmd"
set "LAUNCH_RC=!errorlevel!"
popd
echo.
echo Toolkit beendet (Rueckgabecode !LAUNCH_RC!).
echo.
goto :CONSOLE

:CONSOLE
echo.
echo Die WinPE-CMD steht zur Verfuegung. Keine automatischen Reparaturen.
echo Bei Bedarf X:\NOLS\NOLS-Autostart.cmd erneut ausfuehren.
echo.
endlocal
cmd /k
