# Architektur und Abhängigkeiten

```text
Ventoy (USB)
  ISO/…WinPE.iso                 <-- separat / lokal aus Microsoft ADK gebaut
  NOLS-Toolkit/
    START-RECOVERY.cmd          <-- Tastaturkommando, neue maximierte CMD
    Recovery/Recovery-Launcher.cmd
    Recovery/Modules/*.cmd      <-- Diagnose, Reparatur, Berichte
    Recovery/Modules/HardwareInventur.vbs  <-- benötigt Windows Script Host/WMI
    Recovery/Analyse/offline_analyse.py   <-- Auswertung auf Linux
```

### Hauptfunktionen

`[1–6]` Diagnose (einschließlich Hardware-Preview), `[A–C]` Reparatur,
`[W–Z]` weitere Funktionen, `[8/9/0]` System.

### Optionale GUI

`Launcher.ps1`, `START-HIER.html` und `catalog.json` sind historischer Quellcode für
Windows. Die GUI referenziert etwa 30 externe `Tools/`-Programme. Diese sind nicht
im Repository enthalten. Deshalb wird die GUI **nicht als vollständiges Bundle** beworben.
Das Asset `assets/background.png` war im Audit nur als Dateiname/Größe erfasst,
nicht als Binärdatei übermittelt. Es wird ebenfalls nicht ausgeliefert.

### WinPE-Voraussetzungen

Für die Hardware-VBS sind **WinPE-WMI** und **WinPE-Scripting** erforderlich;
für BitLocker-/TPM-Informationen ergänzend **WinPE-SecureStartup**. Die Verfügbarkeit
von Grafik- und anderen WMI-Providern in WinPE ist eingeschränkt.

### Quelltext-Kodierung

Ältere CMD-Dateien nutzen **CP850 / CRLF**. Deshalb werden unter `toolkit/`
die Originalbytes beibehalten (`.gitattributes`). Quelltext-Editoren sollten
CP850 respektieren; unkontrolliertes UTF-8-Umkodieren kann die Konsolenausgabe beschädigen.
