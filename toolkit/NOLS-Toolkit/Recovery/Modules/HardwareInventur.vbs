Option Explicit
On Error Resume Next
Dim svc, rows, item, n, manufacturer, model, memBytes, cpuName, cpuCores
Dim cpuMHz, cpuArch, tpmSpec, tpmFound, firmwareType, secureStatus
Dim ramState, cpuState, tpmState, biosState, driveCount, gpuCount
Dim reg, v, val, winError, driveSize, diskModel

Function Txt(o, key)
  On Error Resume Next
  Dim t
  Err.Clear
  t = o.Properties_.Item(key).Value
  If Err.Number <> 0 Then
    Txt = "nicht verfuegbar"
  ElseIf IsNull(t) Or IsEmpty(t) Then
    Txt = "nicht verfuegbar"
  Else
    Txt = CStr(t)
  End If
  Err.Clear
End Function

Function Num(o, key)
  On Error Resume Next
  Dim t
  Err.Clear
  t = o.Properties_.Item(key).Value
  If Err.Number <> 0 Or IsNull(t) Or IsEmpty(t) Then
    Num = -1
  ElseIf IsNumeric(t) Then
    Num = CDbl(t)
  Else
    Num = -1
  End If
  Err.Clear
End Function

Function GB(bytes)
  If bytes < 0 Then
    GB = "nicht verfuegbar"
  Else
    GB = CStr(Int(CDbl(bytes) / 1073741824.0 + 0.5)) & " GB"
  End If
End Function

Sub Sep()
  WScript.Echo "----------------------------------------------------------------"
End Sub

Function Q(query)
  On Error Resume Next
  Err.Clear
  Set Q = svc.ExecQuery(query)
  If Err.Number <> 0 Then
    Set Q = Nothing
    Err.Clear
  End If
End Function

Err.Clear
Set svc = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
If Err.Number <> 0 Or (svc Is Nothing) Then
  WScript.Echo "[NICHT VERFUEGBAR] WMI kann nicht gestartet werden."
  WScript.Quit 2
End If
Err.Clear

WScript.Echo "PC / MAINBOARD"
Sep
manufacturer = "nicht verfuegbar"
model = "nicht verfuegbar"
memBytes = -1
Set rows = Q("SELECT Manufacturer,Model,TotalPhysicalMemory FROM Win32_ComputerSystem")
If Not rows Is Nothing Then
  For Each item In rows
    manufacturer = Txt(item, "Manufacturer")
    model = Txt(item, "Model")
    memBytes = Num(item, "TotalPhysicalMemory")
    Exit For
  Next
End If
WScript.Echo "System:   " & manufacturer & " / " & model
Set rows = Q("SELECT Manufacturer,Product FROM Win32_BaseBoard")
If Not rows Is Nothing Then
  For Each item In rows
    WScript.Echo "Board:    " & Txt(item,"Manufacturer") & " / " & Txt(item,"Product")
    Exit For
  Next
Else
  WScript.Echo "Board:    nicht abfragbar"
End If
Set rows = Q("SELECT SMBIOSBIOSVersion,ReleaseDate FROM Win32_BIOS")
If Not rows Is Nothing Then
  For Each item In rows
    WScript.Echo "BIOS:     " & Txt(item,"SMBIOSBIOSVersion")
    Exit For
  Next
End If
WScript.Echo ""

WScript.Echo "PROZESSOR / ARBEITSSPEICHER"
Sep
cpuName = "nicht verfuegbar"
cpuCores = -1
cpuMHz = -1
cpuArch = -1
Set rows = Q("SELECT Name,NumberOfCores,MaxClockSpeed,Architecture FROM Win32_Processor")
If Not rows Is Nothing Then
  For Each item In rows
    cpuName = Txt(item,"Name")
    cpuCores = Num(item,"NumberOfCores")
    cpuMHz = Num(item,"MaxClockSpeed")
    cpuArch = Num(item,"Architecture")
    Exit For
  Next
End If
WScript.Echo "CPU:      " & cpuName
If cpuCores >= 0 Then WScript.Echo "Kerne:    " & CStr(cpuCores)
If cpuMHz >= 0 Then WScript.Echo "Max.Takt: " & CStr(cpuMHz) & " MHz"
WScript.Echo "RAM:      " & GB(memBytes)
Set rows = Q("SELECT Manufacturer,Capacity,Speed FROM Win32_PhysicalMemory")
If Not rows Is Nothing Then
  n = 0
  For Each item In rows
    n = n + 1
    If n <= 12 Then WScript.Echo "  Modul " & n & ": " & GB(Num(item,"Capacity")) & " / " & Txt(item,"Speed") & " MHz"
  Next
End If
WScript.Echo ""

WScript.Echo "DATENTRAEGER / LAUFWERKE"
Sep
driveCount = 0
Set rows = Q("SELECT Index,Model,Size,InterfaceType,MediaType FROM Win32_DiskDrive")
If Not rows Is Nothing Then
  For Each item In rows
    driveCount = driveCount + 1
    If driveCount <= 24 Then
      WScript.Echo "Disk " & Txt(item,"Index") & ": " & Txt(item,"Model")
      WScript.Echo "    " & GB(Num(item,"Size")) & " / " & Txt(item,"InterfaceType") & " / " & Txt(item,"MediaType")
    End If
  Next
End If
If driveCount = 0 Then WScript.Echo "[NICHT VERFUEGBAR] Keine WMI-Datentraegerdaten."
WScript.Echo "Hinweis: Die Recovery-T9 wird ebenfalls aufgelistet."
WScript.Echo ""

WScript.Echo "GRAFIK"
Sep
gpuCount = 0
Set rows = Q("SELECT Name,VideoProcessor FROM Win32_VideoController")
If Not rows Is Nothing Then
  For Each item In rows
    gpuCount = gpuCount + 1
    If gpuCount <= 8 Then WScript.Echo "GPU " & gpuCount & ": " & Txt(item,"Name")
  Next
End If
If gpuCount = 0 Then WScript.Echo "[NICHT VERFUEGBAR] Keine Grafikdaten."
WScript.Echo "WinPE nutzt ggf. einen generischen Anzeigetreiber."
WScript.Echo ""

WScript.Echo "WINDOWS 11 - TECHNISCHE TEILPRUEFUNG"
Sep
ramState = "NICHT PRUEFBAR"
If memBytes >= 0 Then
  If memBytes >= CDbl(4) * CDbl(1073741824) Then
    ramState = "OK (mindestens 4 GB)"
  Else
    ramState = "NICHT ERFUELLT (< 4 GB)"
  End If
End If
WScript.Echo "RAM:      " & ramState
cpuState = "NICHT PRUEFBAR"
If cpuCores >= 0 And cpuMHz > 0 And cpuArch >= 0 Then
  If cpuCores < 2 Or cpuMHz < 1000 Or (cpuArch <> 9 And cpuArch <> 12) Then
    cpuState = "NICHT ERFUELLT (Basiswerte)"
  Else
    cpuState = "BASISWERTE OK; CPU-Freigabeliste OFFEN"
  End If
End If
WScript.Echo "CPU:      " & cpuState

firmwareType = -1
Set reg = GetObject("winmgmts:\\.\root\default:StdRegProv")
If Err.Number = 0 And Not reg Is Nothing Then
  Err.Clear
  val = 0
  reg.GetDWORDValue &H80000002, "SYSTEM\CurrentControlSet\Control", "PEFirmwareType", val
  If Err.Number = 0 Then firmwareType = val
End If
If firmwareType = 2 Then
  biosState = "WinPE im UEFI-Modus gestartet"
ElseIf firmwareType = 1 Then
  biosState = "WinPE im BIOS-Modus gestartet (UEFI-Faehigkeit offen)"
Else
  biosState = "NICHT PRUEFBAR"
End If
WScript.Echo "Firmware: " & biosState
WScript.Echo "SecureBoot: Faehigkeit im WinPE nicht sicher beurteilbar"

tpmSpec = ""
tpmFound = False
Err.Clear
Set rows = Nothing
Dim tpmSvc
Set tpmSvc = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2\security\microsofttpm")
If Err.Number = 0 And Not tpmSvc Is Nothing Then
  Err.Clear
  Set rows = tpmSvc.ExecQuery("SELECT SpecVersion FROM Win32_Tpm")
  If Err.Number = 0 And Not rows Is Nothing Then
    For Each item In rows
      tpmFound = True
      tpmSpec = Txt(item,"SpecVersion")
      Exit For
    Next
  End If
End If
If tpmFound Then
  If InStr(1, tpmSpec,"2.0",vbTextCompare) > 0 Then
    tpmState = "TPM 2.0 gemeldet"
  Else
    tpmState = "PRUEFEN (Spezifikation: " & tpmSpec & ")"
  End If
Else
  tpmState = "NICHT PRUEFBAR (TPM nicht erkannt / nicht verfuegbar)"
End If
WScript.Echo "TPM:      " & tpmState
WScript.Echo "Datentraeger: 64-GB-Systemlaufwerk nicht eindeutig bestimmt"
WScript.Echo "Grafik:   DirectX 12 / WDDM 2.0 nicht geprueft"
WScript.Echo "CPU-Liste: Microsoft-Freigabe nicht geprueft"
WScript.Echo ""
If InStr(ramState,"NICHT ERFUELLT") > 0 Or InStr(cpuState,"NICHT ERFUELLT") > 0 Then
  WScript.Echo "ERGEBNIS: Mindestens ein gepruefter Mindestwert NICHT erfuellt."
Else
  WScript.Echo "ERGEBNIS: Keine abschliessende Windows-11-Freigabe moeglich."
End If
WScript.Echo "Fuer eine finale Aussage weitere offizielle Pruefung noetig."
