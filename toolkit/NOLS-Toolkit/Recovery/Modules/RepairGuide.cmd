@echo off
setlocal EnableExtensions
echo.
echo ===== IT-WERKSTATT RECOVERY - REPARATUR-FAHRPLAN =====
echo.
echo 1. Daten sichern / Klon erstellen, Hardwarezustand prÅfen.
echo 2. Volumes und korrektes Offline-Windows identifizieren.
echo 3. CHKDSK ohne /f und SFC /verifyonly ausfÅhren.
echo 4. DISM /CheckHealth und bei Bedarf /ScanHealth.
echo 5. Falls nîtig: mit Backup und BestÑtigung reparieren.
echo    - DISM /RestoreHealth (passende Quelle kann nîtig sein)
echo    - SFC /scannow (Systemdateien ersetzen)
echo    - CHKDSK /f (Dateisystem reparieren)
echo 6. Ergebnisse prÅfen; bei Fehlern nicht blind wiederholen.
echo.
echo SCHON AKTIV: SFC, DISM, CHKDSK nach RÅckfrage.
echo NICHT AKTIV: EFI-/BCD-Reparatur; Bootrec, BCDBoot.
echo.
echo Bei drohendem DatentrÑgerausfall keine Schreibreparatur!
echo AusfÅhrlich: Recovery\Docs\REPARATUR-FAHRPLAN.txt
exit /b 0
