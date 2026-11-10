@echo off
setlocal EnableExtensions
rem Read-only check: availability varies between ADK WinPE and Setup/WinRE.
echo [INFO] WinPE Werkzeug-Check:
for %%F in (dism.exe diskpart.exe bcdedit.exe bcdboot.exe chkdsk.exe sfc.exe wevtutil.exe manage-bde.exe) do (
    if exist "%SystemRoot%\System32\%%F" (
        echo [OK] %%F
    ) else (
        echo [NICHT VORHANDEN] %%F - entsprechende Funktion separat pruefen
    )
)
exit /b 0
