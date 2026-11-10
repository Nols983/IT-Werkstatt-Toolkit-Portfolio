NOLS IT TOOLKIT RECOVERY v1.6 – Update von v1.5

NEU:
- Umlaute in CMD-Menüs, Eingabeaufforderungen und Modulen (OEM CP850).
- Vollständige Diagnose zeigt CHKDSK, DISM CheckHealth, DISM ScanHealth und SFC VerifyOnly.
- Automatische Diagnose: Nur EINMAL Windows-Laufwerksbuchstabe auswählen.
- Automatische REPARATUR: CHKDSK /f, DISM /RestoreHealth, SFC /scannow.
- Auto-Reparatur bietet CHKDSK allein, DISM+SFC oder alle drei.
- Auch bei Auto-Reparatur nur eine Windows-Laufwerksauswahl und eine ausdrückliche Bestätigung.
- Logs werden unter NOLS-Toolkit\Recovery\Logs\REPAIR_* gespeichert.
- Neustart und Herunterfahren weiterhin über WPEUTIL.

INSTALLATION LINUX:
cd ~/Downloads
unzip NOLS-Toolkit-Recovery-v1.6.zip
cd NOLS-Toolkit-Recovery-v1.6
python3 install.py --dry-run
python3 install.py --apply

START WINPE/RE:
<USB-Laufwerk>:\NOLS-Toolkit\START-RECOVERY.cmd

WICHTIGE SICHERHEITSHINWEISE:
- Nur auf Testgeräten mit Backup beginnen.
- Keine automatischen EFI/BCD-Eingriffe.
- Bei physisch defektem Laufwerk NICHT automatisch reparieren, sondern Daten retten.
- Windows muss lesbar und BitLocker ggf. entsperrt sein.
- /offbootdir wird bei der Automatik auf das ausgewählte Windows-Root gesetzt.
  Bei abweichender Bootpartition SFC-Einzelmodul für manuelle Auswahl nutzen.
- DISM kann eine passende Reparaturquelle benötigen. Eine ISO auf Ventoy allein
  ist keine automatisch eingebundene Quelle. Bei Bedarf DISM-Einzelmodul nutzen.
- CHKDSK /f kann Dateisystemdaten ändern, /r wird nicht ausgeführt.
- DISM/SFC-Ergebnisse sollten anhand der vollständigen Meldungen bewertet werden.
- WinPE-Praxistest der neuen Version steht aus.
- Die CMD-Dateien sind in CP850 codiert; der Launcher setzt chcp 850.

DATEIEN AUF T9:
NOLS-Toolkit\Recovery\Backups\v1.6\  (ersetzte Vorgängerversionen)
NOLS-Toolkit\Recovery\Logs\             (Laufprotokolle)

Alle Windows-Tools, ISOs, Ventoy-Konfiguration und BACKUPS bleiben unangetastet.
