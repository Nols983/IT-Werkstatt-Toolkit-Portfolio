@echo off
setlocal EnableExtensions
echo.
echo ===== DATENTRŽGER / VOLUMES (NUR LESEN) =====
echo DiskPart wird nur mit LIST DISK und LIST VOLUME ausgefhrt.
set "TMPROOT=%TEMP%"
if not defined TMPROOT set "TMPROOT=%SystemRoot%\Temp"
if not exist "%TMPROOT%\" goto manual
set "DPSCRIPT=%TMPROOT%\nols-list-%RANDOM%-%RANDOM%.txt"
> "%DPSCRIPT%" echo list disk
if errorlevel 1 goto manual
>> "%DPSCRIPT%" echo list volume
>> "%DPSCRIPT%" echo exit
if not exist "%SystemRoot%\System32\diskpart.exe" goto manual_clean
diskpart.exe /s "%DPSCRIPT%"
del /f /q "%DPSCRIPT%" >nul 2>&1
echo.
echo ACHTUNG: System/EFI/Recovery-Partitionen nicht ver„ndern.
exit /b 0
:manual_clean
del /f /q "%DPSCRIPT%" >nul 2>&1
:manual
echo Automatisches LIST nicht m”glich. Alternativ manuell:
echo   diskpart
echo   list disk
echo   list volume
echo   exit
exit /b 1
