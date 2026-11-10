@echo off
rem NOLS Recovery OS v1.0 - WinPE startup; Windows PE initializes PnP via wpeinit.
wpeinit
call X:\NOLS\NOLS-Autostart.cmd
