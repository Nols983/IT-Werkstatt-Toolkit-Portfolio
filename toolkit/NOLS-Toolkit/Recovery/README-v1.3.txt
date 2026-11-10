NOLS IT TOOLKIT - RECOVERY MENUE v1.3
====================================

Start unveraendert:
  <T9-Laufwerk>:\NOLS-Toolkit\START-RECOVERY.cmd
Oder automatisch:
  <T9-Laufwerk>:\NOLS-Toolkit\START.cmd

NEUE MENUESTRUKTUR
  [1] DIAGNOSE: Volumes, Windows-Suche, CHKDSK lesend,
      DISM /CheckHealth, Netzwerk, BCD-Anzeige.
  [2] REPARATUR: SFC, DISM /RestoreHealth, CHKDSK /f oder /r,
      Boot/BCD. Derzeit NUR Erlaeuterungen, keine Ausfuehrung!
  [3] HINWEISE: Sicherheits- und Laufwerksinformationen.

WARUM KEINE AUTOMATISCHEN REPARATUREN?
Die v1.3 verbessert vorerst die Menuefuehrung. Erst in einer
weiteren Version sollen Reparaturen nach Zielpruefung, Backup-
Hinweis, Vorschau und ausdruecklicher Bestaetigung folgen.

Bestehende Module und der grafische Windows-Launcher bleiben erhalten.
Der Installer legt eine Sicherung der bisherigen Recovery-Launcher.cmd
im Ordner Recovery/Backups an.

TECHNISCHE EINSCHRAENKUNGEN
Windows Setup / WinPE / WinRE enthalten nicht immer die gleichen
Bordmittel. Der Windows-Laufwerksbuchstabe kann abweichen.
Befehle fuer physisch defekte Datentraeger auch lesend vorsichtig einsetzen.
