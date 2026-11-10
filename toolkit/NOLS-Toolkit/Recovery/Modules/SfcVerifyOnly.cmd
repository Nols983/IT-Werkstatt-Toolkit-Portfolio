@echo off
setlocal EnableExtensions EnableDelayedExpansion
echo.
echo ===== SFC OFFLINE - SYSTEMDATEIEN PRöFEN =====
echo /verifyonly fÅhrt keine Systemdateireparatur durch.
set "WIN="
call "%~dp0ChooseDrive.cmd" WIN WINDOWS
if errorlevel 1 exit /b 1
set "BOOT="
call "%~dp0ChooseBootDir.cmd" BOOT !WIN!
if errorlevel 1 exit /b 1
echo.
echo Ziel-Windows : !WIN!:\Windows
echo Bootverzeich.: !BOOT!:\
echo Befehl: sfc /verifyonly /offbootdir=!BOOT!:\ /offwindir=!WIN!:\Windows
set "CONF="
set /p "CONF=PrÅfung starten? (Y/N): "
if /I not "!CONF!"=="Y" exit /b 0
set "LOGDIR="
if /I "%NOLS_SAVE_LOGS%"=="Y" (
 call "%~dp0MakeLogDir.cmd" LOGDIR SFC_VERIFY
 if errorlevel 1 (
   echo ABBRUCH: Protokollordner auf dem Toolkit-Laufwerk nicht schreibbar.
   exit /b 1
 )
)
if defined LOGDIR (
 sfc.exe /verifyonly /offbootdir=!BOOT!:\ /offwindir=!WIN!:\Windows "/offlogfile=!LOGDIR!\SFC_Detail.log"
) else (
 sfc.exe /verifyonly /offbootdir=!BOOT!:\ /offwindir=!WIN!:\Windows
)
set "RC=!errorlevel!"
if defined LOGDIR (
 >"!LOGDIR!\00_Ergebnis.txt" echo SFC VerifyOnly !WIN!: - Rueckgabecode !RC!
 echo Protokoll: "!LOGDIR!"
)
echo SFC-RÅckgabecode: !RC!
exit /b !RC!
