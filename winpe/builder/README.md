# Reproduzierbarer WinPE-Builder (Phase 3, TEST)

> **Stand 10.11.2026 / v0.2.4 (DISM-InputLocale-Fix):** Der Test unter
> Windows mit v0.2.3 hat die Schritte 1/7 bis 3/7 erfolgreich durchlaufen.
> In Schritt 4/7 wurde `/Image:<mount> /Set-InputLocale:...` durch die
> PowerShell-Operatorbindung faelschlich zu EINEM Argument verbunden.
> DISM meldete Fehler 1639. v0.2.4 trennt die beiden Argumente mit
> zwei benannten Variablen und uebergibt sie als Array. Die uebrigen
> Buildschritte und WinPE-Startdateien bleiben unveraendert.
> **Praxistest abgeschlossen:** v0.2.4 wurde unter Windows mit ADK in allen sieben Build-Schritten erfolgreich ausgefuehrt. Die dabei erzeugte Test-ISO startete ueber Ventoy auf einem Test-PC.
>
> Dieses Verzeichnis enthaelt **keine** Windows-Binärdateien und **keine** ISO.

## Voraussetzungen

- Windows 11 x64, administrative Rechte, mindestens 10 GiB frei auf dem Systemlaufwerk
- Microsoft **Windows ADK** mit Deployment Tools und das dazu passende **WinPE Add-on**
- Nur ein lokales Buildziel auf dem Windows-Systemlaufwerk (`C:` in der Regel)

Der Builder benutzt bewusst die erfolgreich gebooteten WinPE-Startskripte
(`startup/NOLS-Autostart.cmd`, `startup/NOLS-Preflight.cmd`, `startup/startnet.cmd`)
aus dem alten Werkstatt-Buildkit als **technische Ausgangsbasis**. Die innere
Pfadstruktur `X:\NOLS\` und `NOLS-Toolkit\` bleibt erhalten.

## Verwendung auf dem Windows-Build-PC

Entpacke/klone das GitHub-Repository. In einer administrativen CMD:

```cmd
cd /d C:\Pfad\zum\IT-Werkstatt-Toolkit-Portfolio\winpe\builder
BUILD-RECOVERY.cmd --check
```

Wenn die Vorpruefung erfolgreich war:

```cmd
BUILD-RECOVERY.cmd --build
```

Jeder Build erzeugt einen **neuen** lokalen Ordner
`C:\IT-Werkstatt-Build\Run-YYYYMMDD-...\` mit:

```text
WinPE-amd64/                 # Arbeitsverzeichnis (nicht fuer GitHub)
IT-Werkstatt-Recovery-TEST.iso
IT-Werkstatt-Recovery-TEST.iso.sha256
build.log
```

Die ISO kann anschliessend zum Test unter `/ISO` auf eine Ventoy-Partition
kopiert werden. Der Toolkit-Ordner muss **direkt** im Root der Ventoy-
Datenpartition liegen, z. B. `D:\NOLS-Toolkit\START-RECOVERY.cmd`.

## Aufbau und Grenzen

- `copype amd64` und `MakeWinPEMedia /ISO` aus dem Microsoft ADK
- WinPE-WMI → WinPE-Scripting → WinPE-SecureStartup (jeweils mit en-us-CAB)
- `DISM /Set-InputLocale:0407:00000407` fuer deutsches Tastaturlayout
- Das Toolkit setzt bei seinem Start zusaetzlich `wpeutil SetKeyboardLayout`
  und startet eine eigene maximierte CMD (siehe `START-RECOVERY.cmd`).
- Sicherer Abbruch mit `/Discard` fuer noch gemountete neue Arbeitskopien.
- **Keine** Datentraegerformatierung, keine `/UFD`-Aktion, keine bestehende ISO
  wird geaendert oder ueberschrieben.

Bevor eine Test-ISO als Ersatz fuer die bestehende Werkstatt-ISO betrachtet
wird, muessen mindestens der BIOS-/UEFI-Boot, Tastaturlayout, automatischer
Toolkit-Start, WMI/WSH-Hardwareinventur und ein Fall ohne Toolkit geprueft
werden. Die ISO bleibt ein **lokaler Test-Build**; sie gehoert ohne geklaerte
Microsoft-Rechte nicht in einen oeffentlichen GitHub-Release.

## Fehlerbehebung

Bei Fehler 1639 waehrend der WinPE-WMI-Installation mindestens v0.2.4 nutzen.
Die Installation wird jetzt mit `Add-WindowsPackage -Path <Mount> -PackagePath
<CAB> -NoRestart` ausgefuehrt; das DISM-Modul wird in `--check` getestet.
Den vorherigen Fehllauf nicht loeschen oder weiterverwenden.
Vor einem neuen Build in der administrativen CMD mit
`dism /Get-MountedImageInfo` pruefen, ob ein Mount aus dem Fehllauf
zurueckgeblieben ist. Bei erneutem Fehler `build.log` und die zum Fehler
passenden Eintraege in `C:\Windows\Logs\DISM\dism.log` auswerten.


Falls `DISM` beim Mount oder Unmount abbricht, den Build nicht einfach erneut
im gleichen Arbeitsordner starten. Neue Builds verwenden ohnehin neue Ordner.
Erst `DISM /Get-MountedImageInfo` aufrufen, den betroffenen Mount ermitteln
und nur diesen Mount gezielt behandeln. Bei Fehlern den `build.log` pruefen.
Niemals wahllos `DISM /Cleanup-Wim` oder ganze Arbeitsverzeichnisse loeschen.

## Microsoft-Quellen

- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-create-usb-bootable-drive
- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference
- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/wpeinit-and-startnetcmd-using-winpe-startup-scripts
- https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-languages-and-international-servicing-command-line-options

### Hotfix v0.2.3 - Aenderungsumfang

- Nur `BUILD-RECOVERY.ps1` und diese README wurden geaendert.
- Alle Startdateien und `BUILD-RECOVERY.cmd` sind unveraendert.
- Keine Datentraegeroperationen und keine Uebernahme alter Mounts.
- Neue Build-Runs weiterhin ausschliesslich lokal unter `C:\IT-Werkstatt-Build`.
- v0.2.3 ist **noch nicht praktisch unter Windows getestet**.
- Fehler in Schritt 1/7 der v0.2.2 behoben: ADK-Batch-Aufruf geht nicht mehr durch die DISM-Argumentpruefung.
- Paketinstallation bleibt ueber `Add-WindowsPackage` wie in v0.2.2.
- Referenz: https://learn.microsoft.com/en-us/powershell/module/dism/add-windowspackage

### Hotfix v0.2.4 - Deutsches Tastaturlayout / DISM-Argumente

- Fehlerursache in Schritt 4/7: `@('/Image:'+$mountDir,'/Set-InputLocale:...')`
  fuehrt durch die PowerShell-Operatorbindung zu einem einzelnen String.
- Fix: `$intlImageArg` und `$intlLocaleArg` separat erstellen, dann
  `Invoke-Native ... @($intlImageArg, $intlLocaleArg)` aufrufen.
- Erwartete Ausgabe: `dism.exe /Image:C:\...\mount /Set-InputLocale:0407:00000407`
  mit **zwei** voneinander getrennten Schaltern.
- Praxisstatus: v0.2.3 bis 3/7 erfolgreich; v0.2.4-ISO noch nicht gebaut.
- Nur `BUILD-RECOVERY.ps1` und `README.md` geaendert;
  `BUILD-RECOVERY.cmd` und `startup/*` weiterhin byteidentisch zu v0.2.3.
- Bei erneutem Fehler bitte `build.log` aus dem neuen `Run-...`-Ordner teilen.
