NOLS IT TOOLKIT RECOVERY v1.5 - KURZANLEITUNG

NEU IM HAUPTMENUE
 [1] Diagnose - Einzelpruefungen
 [2] Reparatur - vorhandene v1.4 Reparaturfunktionen, jeweils nach Bestaetigung
 [3] Auto-Diagnose - gefuehrte Statuspruefung von Offline-Windows
 [4] Hinweise
 [8] Neustarten via WPEUTIL Reboot (nur WinPE/WinRE)
 [9] Herunterfahren via WPEUTIL Shutdown (nur WinPE/WinRE)
 [0] Zur CMD

AUTOMATISCHE REPARATURDIAGNOSE
 - Zeigt vor jeder Laufwerkswahl DiskPart list disk/list volume.
 - Verlangt eine erreichbare Windows-Installation und eigene Zielauswahl.
 - Schnell: CHKDSK ohne /f, DISM /CheckHealth.
 - Vollstaendig: zusaetzlich DISM /ScanHealth und SFC /verifyonly.
 - Fuer SFC kann ein abweichendes Bootvolume angegeben werden.
 - Fragt vor Beginn explizit nach 'DIAGNOSE'.
 - Erstellt Protokolle auf der Ventoy-Partition in:
   NOLS-Toolkit\Recovery\Logs\AUTO_...\
 - Wertet Rueckgabecodes aus, erfindet aber keine automatische
   Gesundheitsentscheidung. Originalmeldungen sind entscheidend.
 - KEINE automatischen Reparaturen, kein /RestoreHealth, kein /f,
   kein /scannow, kein BCDboot/Bootrec.

SCHUTZ UND GRENZEN
 - X: (WinPE) und das Laufwerk mit dem Toolkit sind ausgeschlossen.
 - Andere externe Laufwerke muessen manuell erkannt werden.
 - BitLocker muss vor der Wahl entsperrt sein.
 - Bei Hardwaredefekt zuerst Datensicherung/Datentraeger-Image.
 - Auch eine Diagnose kann viele Lesezugriffe erzeugen und
   temporaere Logs/Statusdaten schreiben.
 - DISM in WinPE kann bei unterschiedlicher Windows-Version fehlschlagen.
 - Diagnoseberichte koennen Pfade und andere sensible Informationen enthalten.
 - Neustart/Herunterfahren erfolgt mit WPEUTIL, NICHT shutdown.exe.
 - Teste erst auf einem Test-PC, bevor du dies an Kundengeraeten nutzt.

OFFIZIELLE DOKUMENTATION
 https://learn.microsoft.com/de-de/windows-hardware/manufacture/desktop/wpeutil-command-line-options
 https://learn.microsoft.com/de-de/windows-server/administration/windows-commands/sfc
 https://learn.microsoft.com/de-de/windows-server/administration/windows-commands/chkdsk
 https://learn.microsoft.com/de-de/windows-hardware/manufacture/desktop/repair-a-windows-image
