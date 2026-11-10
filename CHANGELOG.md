# Changelog

Die Einträge unterscheiden **Repository-Vorbereitung** und **Werkstatt-Toolkit-Version**.

## Unreleased – Hardwareinventur v2.5 (Praxistest 2026-11-10)

- VBScript-Syntaxfehler in `HardwareInventur.vbs` behoben: ungueltiges numerisches Typ-Suffix `#` entfernt und Byte-/GB-Umrechnung mit `CDbl` korrigiert.
- Unveraendertes Modul- und Menuegeruest: unter Windows und mit lokaler WinPE-Test-ISO ueber Ventoy erfolgreich ausgefuehrt.
- Bei der WinPE-Pruefung wurden CPU, RAM, Mainboard, BIOS, Datentraeger und TPM 2.0 angezeigt; GPU-Abfrage lieferte keine Daten.
- Windows-11-Eignungspruefung bleibt eine Teilpruefung, keine offizielle Freigabe.
- Die lokal erstellte WinPE-Test-ISO und Microsoft-Binaerdateien gehoeren nicht in dieses Repository.

## Repository v0.1 – 2026-11-10 (privater Entwurf)

- 58 bestehende Toolkit-Quellcodedateien aus der T9-Bestandsaufnahme übernommen; **Inhalte unverändert**.
- README und technische Dokumentation aktualisiert, Entwicklungs- und Releaseablauf ergänzt.
- Neue lesende Repository-Prüfungen gegen versehentlich mitverteilte Kundendaten/ISO-/Dump-Dateien sowie fehlende Module.
- GitHub Action kontrolliert die **aktuelle Struktur**, nicht länger starre Alt-Hashes.
- Sieben automatische Tests für die Prüfskripte ergänzt.
- WinPE-Builder bleibt separat als offener Entwicklungsmeilenstein; keine ISO enthalten.

## Werkstattstand – v2.4.2 RC3.1 plus v2.5 Hardware-Preview

- Funktionsfähiges Recovery-Menü und angepasstes Tastatur-/CMD-Startverhalten stammen aus dem letzten Werkstatt-Teststand.
- Hardwareinventur ist Preview; WinPE-Scripting/Provider-Abhängigkeiten sind nicht abschließend gelöst.
- Minidump-Inhaltsanalyse mit WinDbg/CDB bleibt offen.

> Frühere Versionsdokumente befinden sich unverändert unter `toolkit/NOLS-Toolkit/Recovery/Docs/`.

## Unreleased – Phase 3 (WinPE Builder, Testentwurf)

- Separater ADK-Builder fuer lokale WinPE-TEST-ISOs hinzugefuegt.
- Funktionierende alte Startup-Skripte als Quelle uebernommen.
- WMI, Scripting, SecureStartup und Standard-DE-Tastatur vorgesehen.
- Keine Microsoft-Binärdateien; echter Windows-/Boot-Test steht aus.
