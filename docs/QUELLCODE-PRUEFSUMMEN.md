# Quelltext-Rekonstruktion (2026-11-10)

Im Audit wurden 58 Quelldateien als UTF-8-Text ausgegeben. Der Python-Export
veränderte teilweise CP850 und CRLF. Für diesen GitHub-Entwurf wurden die
**Originalbytes für alle 58 Dateien über die im Audit dokumentierten
SHA-256-Hashes** rekonstruiert. Die frühere `START-HIER.html` hatte im Audit
zusätzlich eine endständige LF-Zeile erhalten, die im Original fehlte.

Mit `python3 scripts/verify_sources.py` kann die Übereinstimmung geprüft werden.

Die Prüfsummen dokumentieren **nur den historischen Ausgangs-Snapshot**.
Quellcodeänderungen in späteren Commits sind normal und erfordern **keine**
Änderung dieses historischen Manifests. `verify_sources.py` ist bewusst nicht
Bestandteil der automatischen GitHub-Push-Checks.
