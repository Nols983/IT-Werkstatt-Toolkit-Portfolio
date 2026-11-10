IT-WERKSTATT TOOLKIT v2.4.2 RC3 - RECOVERY
==========================================
Entwicklung: Nols

Start im eigenen WinPE: automatisch ueber START-RECOVERY.cmd.
Das Skript aktiviert nach Moeglichkeit die deutsche Tastaturbelegung
(QWERTZ) und startet fuer die Wirkung eine neue CMD.
Manuell: <USB>:\NOLS-Toolkit\START-RECOVERY.cmd

Diagnose / Fehleranalyse / Datentraeger / BSOD / Treiber:
- Nur lesende Untersuchungen, ohne automatische Reparatur.
- Fehlende Logs oder Minidumps bedeuten nicht, dass keine Fehler vorliegen.
- Eine .sys-Datei im Treiberinventar ist kein Nachweis der BSOD-Ursache.

Reparaturen:
- Schreiben auf das ausgewaehlte Windows-Volume.
- Vorher BitLocker-Status, Backup und Ziellaufwerk kontrollieren.
- Vor jeder schreibenden Reparatur wird der physische USB-Datentraeger
  ueber DiskPart ausgeschlossen. Bei unklarer Zuordnung: ABBRUCH.
- CHKDSK /f benoetigt jetzt eine lesbare Windows-Installation.
- UEFI-Bootreparatur: manuell gepruefte GPT-ESP, BCD-Backup.

Hauptmenue:
- Diagnose [1] bis [5], Reparatur [A] bis [C].
- Weitere Funktionen [W] bis [Z], System [8], [9], [0].
- Untermenue-Tasten bleiben wie bisher.

Protokolle:
- Wahlweise auf dem Toolkit-Laufwerk unter Recovery/Logs.
- Ueber [X] Berichte nach Fallordner waehlen.
- BCD-Pflichtsicherungen bleiben bei Bootreparatur erhalten.

Grenzen / offene Tests:
- Physische Datentraegerzuordnung braucht WinPE-Praxistest auf
  Test-PC mit mehreren Partitionen, bevor Kollegen schreiben duerfen.
- WinDbg/CDB-Dump-Inhaltsanalyse ist nicht enthalten/getestet.
- Die Windows-GUI mit Tools-Katalog gehoert NICHT zur Recovery-only-
  Kollegen-Edition; externe Programme nur nach Lizenzpruefung verteilen.
- Bei vermuteten I/O-Defekten zuerst sichern, keine Belastung mit CHKDSK.

Alte README-vX-Dateien sind historische Dokumentation, keine Anleitung.

Tastaturwechsel: Hauptmenue [W], Deutsch oder Englisch waehlen.
WinPE startet danach eine neue CMD fuer die geaenderte Belegung.
