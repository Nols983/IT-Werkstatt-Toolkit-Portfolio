@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Aufruf: call ChooseDrive.cmd VARIABLE [WINDOWS]
rem Bei WINDOWS muss eine erreichbare Windows-Installation vorhanden sein.
if "%~1"=="" exit /b 2
set "KIND=%~2"
set "VALID="
set "INPUT="
echo.
echo ===== DATENTRéGER UND VOLUMES =====
echo Die Laufwerksbuchstaben in WinPE kînnen von Windows abweichen.
if exist "%~dp0Volumes.cmd" (
    call "%~dp0Volumes.cmd"
) else (
    echo HINWEIS: Volumes.cmd nicht gefunden, DiskPart bitte manuell starten.
)
echo.
if /I "!KIND!"=="WINDOWS" (
    echo Suche erreichbare Windows-Installationen:
    for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
        if exist "%%D:\Windows\System32\Config\SYSTEM" echo   %%D:\Windows
    )
)
echo.
set /p "INPUT=Laufwerksbuchstabe eingeben (z.B. C oder C:): "
if not defined INPUT goto invalid
if "!INPUT:~-1!"==":" set "INPUT=!INPUT:~0,-1!"
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if /I "!INPUT!"=="%%D" set "VALID=%%D"
)
if not defined VALID goto invalid
if /I "!VALID!:"=="%~d0" (
    echo ABBRUCH: Das ist das Laufwerk des Recovery-Toolkits!
    endlocal & exit /b 1
)
if not exist "!VALID!:\" goto invalid
if /I "!KIND!"=="WINDOWS" (
    if not exist "!VALID!:\Windows\System32\Config\SYSTEM" (
        echo Kein lesbares Windows unter !VALID!:\Windows.
        echo Mîgliche Ursachen: falsches Volume oder BitLocker-Sperre.
        endlocal & exit /b 1
    )
)
echo.
echo AusgewÑhlt: !VALID!:
endlocal & set "%~1=%VALID%" & exit /b 0
:invalid
echo ABBRUCH: UngÅltiger Buchstabe oder Laufwerk nicht erreichbar.
echo X: ist fÅr die WinPE-RAM-Umgebung gesperrt.
endlocal & exit /b 1
