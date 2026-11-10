@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem MakeLogDir.cmd OUTPUT_VAR PREFIX. Called only if NOLS_SAVE_LOGS=Y.
if "%~1"=="" exit /b 2
if /I not "%NOLS_SAVE_LOGS%"=="Y" exit /b 2
set "BASE=%~dp0..\Logs"
if not exist "%BASE%\" md "%BASE%" >nul 2>&1
if not exist "%BASE%\" exit /b 1
set "DIR=%BASE%\%~2_%RANDOM%_%RANDOM%"
if exist "%DIR%\" exit /b 1
md "%DIR%" >nul 2>&1
if not exist "%DIR%\" exit /b 1
>"%DIR%\write.tmp" echo test
if errorlevel 1 exit /b 1
del /q "%DIR%\write.tmp" >nul 2>&1
endlocal & set "%~1=%DIR%" & exit /b 0
