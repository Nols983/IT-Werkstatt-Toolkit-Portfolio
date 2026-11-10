# WinPE-Startskripte – **technischer Entwurf**

**Hier liegt KEIN fertiges WinPE-Buildsystem und keine Microsoft-ISO.**
Das `winpe/startnet.cmd` und `winpe/ITW-Autostart.cmd` sind bewusst von den
stabilen Toolkit-Modulen getrennte Entwürfe. Sie wurden noch **nicht** auf
realer Hardware gebootet.

## Lokaler Build (Microsoft ADK)

Die Windows-ADK-Bereitstellungstools und das passende Windows-PE-Add-on werden
auf Windows selbst installiert. Für den Build:

1. In der administrativen *Deployment and Imaging Tools Environment*:
   `copype amd64 C:\WinPE_ITW`
2. `boot.wim` mit DISM nach `C:\WinPE_ITW\mount` einbinden.
3. Benötigte Microsoft-WinPE-Optional-Components hinzufügen (in der Regel
   `WinPE-WMI`, `WinPE-Scripting`, `WinPE-SecureStartup` und passende Sprachpakete).
4. Beide Startskripte im WIM nach `Windows\System32\startnet.cmd` und
   `ITW\ITW-Autostart.cmd` kopieren (Autostart-Pfad bei Bedarf anpassen).
5. WIM mit DISM **/Commit** aushängen.
6. `MakeWinPEMedia /ISO C:\WinPE_ITW C:\ITW-Recovery-TEST.iso`
7. Eigenen BIOS-/UEFI-Boot-Test über Ventoy durchführen.

Diese Schritte sind eine **Anleitung**, kein getesteter One-Click-Builder.
Die erfolgreichen Werkstatt-Buildskripte waren **nicht im T9-Audit enthalten**;
sie werden nicht als validiertes Veröffentlichungsartefakt ausgegeben.

## Linux

Die von Microsoft erzeugten ISO-Strukturen sollten nicht blind mit
`xorriso` neu gemastert werden: El-Torito-/EFI-Bootmetadaten können
verloren gehen. Für einen reproduzierbaren Build ist Microsofts ADK der
bevorzugte Weg.

## Neuer Build-Entwurf aus Phase 3

Ein separater, reproduzierbarer Builder liegt unter [`builder/`](builder/README.md).
Er basiert auf den ehemals erfolgreich gebooteten Startskripten, ist aber selbst
noch nicht unter Windows gebaut oder gebootet worden. Keine Microsoft-Binärdateien enthalten.
