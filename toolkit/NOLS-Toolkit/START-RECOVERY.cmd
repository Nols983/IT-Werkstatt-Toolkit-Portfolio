@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem IT-WERKSTATT TOOLKIT - Start von USB unter WinPE/WinRE
rem Laufwerksbuchstaben und ISO-Inhalt bleiben unveraendert.
if not exist "%~dp0Recovery\Recovery-Launcher.cmd" (
    echo FEHLER: Recovery-Launcher fehlt.
    exit /b 1
)
rem WinPE-Tastatur DE (QWERTZ) - gilt laut Microsoft fuer neue Prozesse.
if exist "%SystemRoot%\System32\wpeutil.exe" (
    "%SystemRoot%\System32\wpeutil.exe" SetKeyboardLayout 0407:00000407 >nul 2>&1
    if errorlevel 1 echo HINWEIS: DE-Tastatur konnte nicht aktiviert werden.
)
rem NEUES CMD-FENSTER nach SetKeyboardLayout (nicht nur /c im selben Fenster).
rem /wait: Nach Ende des Launchers zur vorhandenen WinPE-CMD zurueck.
start "" /MAX /WAIT "%ComSpec%" /d /c call "%~dp0Recovery\Recovery-Launcher.cmd"
exit /b %errorlevel%
