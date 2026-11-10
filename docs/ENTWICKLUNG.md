# Entwicklungsworkflow

## Grundsatz: Git = Quelle, T9 = Testmedium

Das Repository ist nach dem ersten geprüften Import die zentrale Quelle. Änderungen an der Samsung T9 passieren **erst nach** nachvollziehbarer Entwicklung und angemessenen Tests.

1. Lokal das private Repository aktualisieren (`git pull`).
2. Für eine Änderung einen Branch erstellen, z. B. `git switch -c feature/hardware-inventur`.
3. Möglichst **vorhandene Module erweitern**, keine parallelen Skripte mit derselben Funktion anlegen.
4. Prüfen: `python3 scripts/check_repository.py` und `python3 -m unittest discover -s tests -v`.
5. Bei CMD-/VBS-Änderungen: **CP850 und Windows-Zeilenenden (CRLF) respektieren**. Keine automatische Umkodierung des Toolkit-Quellbestands.
6. Änderungen dokumentieren und committen. Vor WinPE-Tests Backup der betroffenen T9-Dateien erstellen.
7. Nach einem Test bekannte Einschränkungen unter `docs/TESTSTATUS.md` aktualisieren.
8. Erst nach erfolgreichen Tests einen Release-Tag setzen und separat das distributierbare Werkzeugpaket bauen.

### Konkrete Arbeitsteilung

- **ChatGPT:** Änderungen und Tests vorbereiten; bei größeren Änderungen ein prüfbares ZIP/Patch bereitstellen.
- **Nols:** Auf dem Notebook Änderungen kontrollieren, Commit/Push ausführen, WinPE- und Hardwaretests durchführen.
- **GitHub:** Verlauf, Issues, Pull Requests und die statischen automatisierten Prüfungen.

### Baseline-Hashes

`scripts/original_source_hashes.json` dokumentiert den Ausgangsstand vom 10.11.2026. `scripts/verify_sources.py` ist eine **historische Baseline-Prüfung**, kein obligatorischer CI-Test für zukünftige Änderungen.

### Keine automatisierten Reparaturtests auf echten Kundendatenträgern

Das neue Testsystem führt **keine** CMD-Module unter Windows aus. Es prüft nur Syntax/Struktur auf Dateiebene. Echte Reparaturszenarien brauchen bewusst ausgewählte, gesicherte Testmaschinen/VMs.
