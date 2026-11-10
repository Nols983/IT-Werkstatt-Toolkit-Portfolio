@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Aufruf: call ChooseBootDir.cmd VARIABLE WINDOWSBUCHSTABE
if "%~1"=="" exit /b 2
set "BOOT=%~2"
if not defined BOOT exit /b 2
echo.
echo SFC ben”tigt /offbootdir UND /offwindir.
echo Standard: Bootverzeichnis = !BOOT!:\
echo Bei abweichendem Bootvolume musst du das korrekte Volume kennen.
echo Eine EFI-Partition ohne Buchstaben wird NICHT automatisch eingehangen.
set "ANSWER="
set /p "ANSWER=Abweichendes Bootvolume ausw„hlen? (Y/N, Enter=N): "
if /I "!ANSWER!"=="Y" (
    call "%~dp0ChooseDrive.cmd" BOOT
    if errorlevel 1 exit /b 1
)
endlocal & set "%~1=%BOOT%" & exit /b 0
