# Phase 1–2: Struktur-, Quellcode- und Freigabeprüfung

**Basis:** `IT-Werkstatt-GitHub-Entwurf(1).zip` aus der T9-Bestandsaufnahme vom 10.11.2026.

## Unverändert

- 58 vorhandene Toolkit-Dateien wurden **nicht geändert**; ihr bytegenauer SHA-256-Ausgangsstand ist in `scripts/original_source_hashes.json` dokumentiert.
- Startlogik inklusive QWERTZ und `/MAX /WAIT` blieb erhalten.
- Originalmodule für SFC, DISM, CHKDSK, Boot, Datenträger-, Fehler- und Treiberanalyse bleiben unverändert.

## Neu in Repository v0.1

- Überarbeitete deutsche Projektbeschreibung mit überprüfbarem Status.
- Read-only Scanner `scripts/check_repository.py` und Unit-Tests.
- `.github/workflows/validate.yml` prüft den **aktuellen** Quellstand bei Push/PR.
- Historische SHA-256-Prüfung bleibt optional (`scripts/verify_sources.py`).
- Dokumentation für Entwicklungsworkflow, GitHub-Einrichtung und aktuelle Testgrenzen.

## Noch offen / bewusst nicht gelöst

- Keine WinPE-Binärdateien und **kein** produktionsreifer öffentlicher WinPE-Builder.
- Keine Entscheidung über Open-Source-Lizenz; **keine `LICENSE`-Datei**.
- Kein Security-Audit durch unabhängige Dritte und keine vollständige Geheimniserkennung.
- Kein Windows-/WinPE-Laufzeittest der 58 Quellcodedateien in diesem Arbeitspaket.
- Die Windows-GUI bleibt ohne `Tools/` nur teilweise nutzbar.
- Die im Entwurf enthaltenen `winpe/*.cmd` sind **ungetestete Startskriptvorschläge** und nicht die Bytes der gebooteten ISO.

## Veröffentlichungsentscheidung

**Private GitHub-Vorbereitung zulässig als Arbeitsziel; öffentliches Release noch nicht freigegeben.** Vor öffentlicher Sichtbarkeit sind manuelle Geheimnis-/Rechtekontrolle, Lizenzwahl, Build- und Laufzeittests sowie eine Entscheidung über WinPE-Nutzungsbedingungen nötig.
