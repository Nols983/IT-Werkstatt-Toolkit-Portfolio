# Teststand und offene Prüfungen

Stand: 10. November 2026. Die Ergebnisse gelten für den bisher getesteten Werkstatt-PC und die dokumentierten Szenarien, nicht für beliebige Geräte oder Fehlerbilder.

| Bereich | Nachgewiesen | Noch offen |
| --- | --- | --- |
| WinPE-Builder v0.2.4 | Unter Windows mit Microsoft ADK alle sieben Build-Phasen erfolgreich abgeschlossen; separate Test-ISO erstellt | Reproduktion auf weiteren ADK-/Windows-Versionen |
| Start über Ventoy | Neue ISO auf einem Test-PC gestartet | Weitere BIOS-/UEFI-Konstellationen |
| Recovery-Menü | Toolkit-Suche, Autostart, deutsches Tastaturlayout und Bedienung auf Test-PC geprüft | Weitere Laufwerks- und Gerätekombinationen |
| Hardwareinventur v2.5 | Unter Windows und WinPE: CPU, RAM, Mainboard, BIOS, Datenträger und TPM ausgelesen | GPU-Daten in WinPE nicht verfügbar; weitere Hardware prüfen |
| Windows-11-Teilprüfung | Einzelne technische Merkmale ausgegeben | Keine vollständige Hardware- oder Kompatibilitätsfreigabe |
| Bootreparatur | Frühere Module in einem Windows-Testfall praktisch verwendet | Änderungen nur mit Backup und geeignetem Testsystem prüfen |
| USB-Zielschutz | Frühere Werkstatttests erfolgreich gemeldet | DiskPart-Auswertung für Sprach-, Geräte- und Partitionsvarianten nicht vollständig abgesichert |
| Offline-Ereignis- und Speicheranalyse | Mit früheren Testprotokollen ausgeführt | Weitere reale Fehlerfälle prüfen |
| BSOD-/Treiberanalyse | Drittanbietertreiber und Dump-Fundstellen in bisherigen Tests erfasst | Inhaltliche Minidump-Analyse mit WinDbg/CDB bei geeignetem Fehlerfall |
| Automatisierte Tests | 17 Repository- und Builder-Regressionstests unter Ubuntu erfolgreich | Keine Windows- oder WinPE-Laufzeittests in GitHub Actions |

## Grenzen

- Der WinPE-Builder wurde praktisch ausgeführt, die CI führt jedoch ausschließlich statische Tests durch.
- Schreibende Reparaturfunktionen benötigen vor dem Start eine gesonderte Prüfung von Zielvolume, BitLocker-Status und Backup.
- `WriteTargetGuard.cmd` nutzt lokalisierungsabhängige DiskPart-Textausgaben. Eine umfassende Absicherung des Schreibschutzes ist nicht nachgewiesen.
- WinPE bietet nicht dieselben WMI-Provider und Treiber wie eine vollständige Windows-Installation.
- Ein gefundenes Ereignis, ein Treiber oder ein Minidump ist für sich allein kein Nachweis einer Fehlerursache.
