# Installation und Start (Entwurf)

1. Ein USB-Medium mit Ventoy muss bereits eingerichtet sein (Ventoy-Erstinstallation kann Daten löschen).
2. `toolkit/NOLS-Toolkit/` an die **Wurzel der Ventoy-Datenpartition** kopieren.
3. Eine **selbst aus dem Microsoft ADK erzeugte und lokal getestete** WinPE-ISO auf das Ventoy-Medium kopieren,
   z. B. nach `ISO/IT-Werkstatt-Recovery.iso`.
4. Die ISO booten. Der Autostart sucht `NOLS-Toolkit/START-RECOVERY.cmd` auf zugänglichen Volumes.

Die interne Ordnerbezeichnung `NOLS-Toolkit` darf nicht ohne Anpassung des Autostarts geändert werden.
Es wird **keine öffentliche, fertige WinPE-ISO mitgeliefert**.

## Vor dem Reparieren

- Backup vorhandener Kundendaten sicherstellen.
- Ein mögliches BitLocker-Volume zuerst rechtmäßig entsperren.
- Datenträger-/USB-Zuordnung und Windows-Ziel zweimal überprüfen.
- Schreibeingriffe (SFC-Reparatur, DISM RestoreHealth, CHKDSK /f, BCDBoot) nur bewusst starten.

## Protokolle

Bei aktivierter Protokollierung entstehen Ausgaben unter `NOLS-Toolkit/Recovery/Logs/`.
Das Verzeichnis wird bei Bedarf zur Laufzeit erstellt. **Keine Kundendaten committen.**
