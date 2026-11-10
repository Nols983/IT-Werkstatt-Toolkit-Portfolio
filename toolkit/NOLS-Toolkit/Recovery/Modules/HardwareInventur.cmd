@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 850 >nul 2>&1
cls
echo ================================================================
echo              HARDWAREINVENTUR / WINDOWS-11-CHECK
echo ================================================================
echo.
echo Nur lesende Abfragen. Es werden keine Datentraeger geaendert.
echo Hardwaredaten stammen vom gebooteten PC, nicht vom Offline-Windows.
echo.
set "CSCRIPT=%SystemRoot%\System32\cscript.exe"
set "VBS=%~dp0HardwareInventur.vbs"
if not exist "%CSCRIPT%" goto FALLBACK
if not exist "%VBS%" goto FALLBACK
"%CSCRIPT%" //NoLogo "%VBS%"
if not errorlevel 1 goto DONE
echo [HINWEIS] WMI-Skript konnte nicht vollstaendig ausgefuehrt werden.
:FALLBACK
echo [HINWEIS] Vollstaendige WMI-Hardwareinventur nicht verfuegbar.
echo.
echo ================== EINGESCHRAENKTE ABFRAGE ====================
echo CPU-Name aus Hardware-Registry:
reg query "HKLM\HARDWARE\DESCRIPTION\System\CentralProcessor\0" /v ProcessorNameString 2>nul
echo.
echo DiskPart: erkannte Laufwerke (keine Aenderungen):
set "DPSCRIPT=%SystemRoot%\Temp\ITW_HW_%RANDOM%_%RANDOM%.txt"
>"%DPSCRIPT%" echo list disk
if exist "%DPSCRIPT%" (
    diskpart /s "%DPSCRIPT%"
    del /q "%DPSCRIPT%" >nul 2>&1
)
echo.
echo [NICHT GEPRUEFT] RAM, Mainboard, GPU, TPM und CPU-Freigabeliste.
echo [NICHT GEPRUEFT] Windows-11-Gesamteignung.
echo Vollstaendige Hardwareinventur erfordert WinPE-WMI
echo und Windows Script Host ^(WinPE-Scripting^).
:DONE
echo.
echo Windows-11-Hinweis: CPU-Freigabeliste, DX12/WDDM und Secure-Boot-
echo Faehigkeit sind offline aus WinPE nicht vollstaendig pruefbar.
echo Dies ist KEINE offizielle Windows-11-Freigabe.
exit /b 0
