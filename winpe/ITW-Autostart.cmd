@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "KIT="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined KIT if exist "%%D:\NOLS-Toolkit\START-RECOVERY.cmd" set "KIT=%%D:\NOLS-Toolkit\START-RECOVERY.cmd"
if not defined KIT (
    echo IT-Werkstatt Toolkit wurde auf keinem Volume gefunden.
    echo Pruefe das USB-Medium. Eine CMD bleibt verfuegbar.
    cmd /k
    exit /b 1
)
call "%KIT%"
echo.
echo IT-Werkstatt Toolkit wurde beendet. CMD als Rueckfallebene.
cmd /k
