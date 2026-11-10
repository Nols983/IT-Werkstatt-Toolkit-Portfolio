NOLS IT TOOLKIT - RECOVERY v1.4
===============================
Neu:
- Einfache Hauptkategorien: Diagnose / Reparatur / Hinweise.
- Vor jeder Buchstaben-Abfrage automatische Ausgabe von LIST DISK
  und LIST VOLUME (DiskPart, nur LIST-Befehle).
- DIAGNOSE: SFC /verifyonly, DISM /ScanHealth, alte Diagnosen.
- REPARATUR: SFC /scannow, DISM /RestoreHealth, CHKDSK /f.
- Vor Schreibreparaturen exakte Zielbestaetigung (z. B. SFC D).
- Kein automatisches Formatieren, Partitionieren, BCDBoot oder Bootrec.
- Keine PowerShell erforderlich; CMD in WinPE/WinRE genuegt.

ACHTUNG: SFC, DISM und CHKDSK-Reparaturen koennen Daten veraendern.
Bei defekter Hardware zuerst Daten/Partitionen sichern oder klonen.
BitLocker-Laufwerke muessen bei Bedarf erst entsperrt werden.
Die Quelle fuer DISM /RestoreHealth ist nicht automatisch vorhanden;
bei fehlender Quelle kann DISM mit einem Fehler abbrechen.

Installation (Ubuntu):
  cd ~/Downloads
  unzip NOLS-Toolkit-Recovery-v1.4.zip
  cd NOLS-Toolkit-Recovery-v1.4
  python3 install.py --dry-run
  python3 install.py --apply

Start WinPE/WinRE (nach Suche des T9-Buchstabens):
  D:\NOLS-Toolkit\START-RECOVERY.cmd

Wiederherstellung vorheriger Module nach Bedarf:
  NOLS-Toolkit\Recovery\Backups\v1.4\

Hinweis: Es wurde eine statische Pruefung und ein simulierter
Installationslauf durchgefuehrt; ein echter WinPE-Starttest steht aus.
