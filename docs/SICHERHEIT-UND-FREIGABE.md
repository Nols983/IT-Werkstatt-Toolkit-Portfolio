# Veröffentlichungsprüfung

Diese Datei dokumentiert die Vorbereitung einer separaten öffentlichen Portfolio-Version. Das eigentliche Entwicklungsrepository bleibt privat. Eine Veröffentlichung ist noch nicht freigegeben.

## Technischer Prüfstand

Stand: 10. November 2026

- Der lokale Preflight hat den aktuellen Repository-Stand und sieben erreichbare Commits untersucht. Er meldete keine Treffer in seinen Mustern für Zugangsdaten, private IP-Adressen oder interne Domains.
- Sieben Hinweise betrafen lokale Ventoy-Pfade in drei Dokumentationen. Diese Pfade wurden in der separaten Vorschau neutralisiert; die Vorschau enthält keine private Git-Historie.
- Die Vorschau enthält 86 exportierte Dateien. Die Repository-Prüfung und alle 17 automatisierten Tests waren unter Ubuntu erfolgreich.
- In der aktuellen Dateiliste befinden sich keine fertige Microsoft-WinPE-ISO, `boot.wim` oder gebündelte Drittanbieterprogramme.
- Der WinPE-Builder v0.2.4 wurde unter Windows erfolgreich ausgeführt. Die daraus erzeugte Test-ISO wurde auf einem Test-PC über Ventoy gestartet; die Hardwareinventur funktionierte unter Windows und WinPE.

Diese Ergebnisse sind **keine** vollständige Prüfung von Rechten, personenbezogenen Inhalten oder Lizenzbedingungen. Automatische Muster können vertrauliche Angaben übersehen.

## Vor einer öffentlichen Freigabe

- [ ] Urheberschaft und Nutzungsrechte klären, insbesondere mögliche Rechte des Arbeitgebers und Beiträge Dritter.
- [ ] Drittanbieter-Namen, Tool-Verweise und Materialien auf erforderliche Hinweise oder Erlaubnisse prüfen.
- [ ] Entscheiden, ob für den eigenen Quellcode eine Open-Source-Lizenz vergeben werden soll. Ohne Lizenz keine allgemeine Nutzungserlaubnis behaupten.
- [ ] README-Verweise, CI-Badge und Klon-URL an **das neue öffentliche Repository** anpassen. Der aktuelle Link verweist noch auf das private Entwicklungsrepository.
- [ ] Nur echte, anonymisierte Screenshots ohne Kunden-, Geräte- oder Wiederherstellungsdaten aufnehmen.
- [ ] Neue Portfolio-Version zunächst privat anlegen und deren Dateibaum sowie ersten Commit prüfen; erst danach bewusst öffentlich schalten.

## Sicherheitsgrenzen des Toolkits

`WriteTargetGuard.cmd` wertet textuelle DiskPart-Ausgaben aus. Der bestehende Schutz ist nicht für alle Sprachen, Geräte- und Partitionskonstellationen nachgewiesen. Schreibende Aktionen nur nach eigenständiger Kontrolle des Zieldatenträgers, Verschlüsselungsstatus und vorhandener Sicherungen ausführen.

Die GitHub-Action führt statische Quellcodeprüfungen aus. Sie ersetzt weder einen vollständigen Windows-/WinPE-Build noch einen Boot-Test. Einzelheiten: [`TESTSTATUS.md`](TESTSTATUS.md).

Eine fertige WinPE-ISO oder Microsoft-Binärdateien werden nicht öffentlich bereitgestellt. Lizenzhinweise stehen in [`LIZENZ-UND-WINPE.md`](LIZENZ-UND-WINPE.md).
