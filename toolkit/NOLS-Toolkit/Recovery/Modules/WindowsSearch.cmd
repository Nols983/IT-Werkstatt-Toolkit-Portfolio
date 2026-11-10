@echo off
setlocal EnableExtensions
echo.
echo ===== WINDOWS INSTALLATIONEN SUCHEN =====
echo Suche nach Windows\System32\Config\SYSTEM (ohne Schreibzugriff).
echo.
set /a COUNT=0
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if exist "%%D:\Windows\System32\Config\SYSTEM" (
        echo   GEFUNDEN: %%D:\Windows
        set /a COUNT+=1 >nul
    )
)
echo.
echo Hinweis: BitLocker-gesperrte oder nicht eingebundene Volumes
 echo          bleiben unter Umstaenden unsichtbar.
echo          X: ist meistens die temporaere WinPE-Umgebung.
exit /b 0
