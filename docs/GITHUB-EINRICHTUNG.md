# Portfolio-Repository veröffentlichen

Die öffentliche Projektversion wird **getrennt** vom privaten Entwicklungsrepository geführt. Dadurch bleiben historische Commits, lokale Arbeitsstände und nicht für die Veröffentlichung vorgesehene Inhalte privat.

## Ausgangslage

- Quellprojekt: privates Git-Repository mit Entwicklungsverlauf.
- Portfolio-Vorschau: exportierter, bereinigter Quellstand **ohne** `.git`-Verzeichnis.
- Ziel: neues Repository mit eigenem ersten Commit, ohne Übernahme der privaten Historie.

Der Export enthält den getesteten Quellcode und die Projektstruktur, jedoch keine fertige WinPE-ISO und keine gebündelten Drittanbieterwerkzeuge. Er wurde unter Ubuntu mit `scripts/check_repository.py` und 17 Unit-Tests geprüft.

## Vor der Veröffentlichung

1. Die Punkte in [`SICHERHEIT-UND-FREIGABE.md`](SICHERHEIT-UND-FREIGABE.md) abarbeiten, insbesondere Rechte und Lizenzwahl.
2. Namen und URL des neuen **öffentlichen** Repositories festlegen.
3. In `README.md` den CI-Badge und die Klon-URL auf das neue Repository umstellen. Aktuell zeigen sie noch auf das private Entwicklungsrepository.
4. Dokumentationen, Dateibaum und geplante Screenshots manuell kontrollieren.
5. Das neue Repository zunächst **privat** erstellen; die bereinigte Vorschau mit einem neuen Initial-Commit hochladen. Keine private Git-Historie importieren oder das Entwicklungsrepository umbenennen bzw. überschreiben.
6. Die GitHub Actions des neuen Repositories prüfen; anschließend nach bewusster Freigabe auf **öffentlich** stellen.
7. Beschreibung, Topics und Profil-Pin setzen.

## Pflege nach der Veröffentlichung

Änderungen werden zunächst im privaten Quellprojekt entwickelt und getestet. Für die Portfolio-Version wird jeweils ein bereinigter Stand exportiert, überprüft und separat übernommen. Der private Entwicklungsverlauf wird nicht automatisch gespiegelt.

Eine öffentliche Repository-Ansicht ist nicht gleich eine Open-Source-Lizenz. Siehe [`LIZENZ-UND-WINPE.md`](LIZENZ-UND-WINPE.md).
