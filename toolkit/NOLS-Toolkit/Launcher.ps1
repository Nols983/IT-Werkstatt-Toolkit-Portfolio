# IT-WERKSTATT TOOLKIT - Portable Windows GUI
# Windows 10/11 with Windows PowerShell 5.1, no external dependencies.
# Only explicit clicks launch programs. Nothing is started automatically.
# Run from NOLS-Toolkit directly under the VENTOY partition root.

$ErrorActionPreference = 'Stop'
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName Microsoft.VisualBasic
} catch { Write-Host "Windows Forms ist nicht verfuegbar: $($_.Exception.Message)"; exit 1 }

[System.Windows.Forms.Application]::EnableVisualStyles()
$script:KitDir = $PSScriptRoot
$script:Root = [System.IO.Path]::GetFullPath((Join-Path $KitDir '..'))
$script:CatalogPath = Join-Path $KitDir 'catalog.json'
if (-not (Test-Path -LiteralPath $script:CatalogPath -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show('catalog.json fehlt. Bitte das Paket vollstaendig kopieren.','IT-Werkstatt Toolkit') | Out-Null
    exit 1
}
try { $script:Catalog = Get-Content -LiteralPath $script:CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { [System.Windows.Forms.MessageBox]::Show("Katalog kann nicht gelesen werden: $($_.Exception.Message)",'IT-Werkstatt Toolkit') | Out-Null; exit 1 }

function Rgb([int]$r,[int]$g,[int]$b) { return [System.Drawing.Color]::FromArgb($r,$g,$b) }
$script:C = @{
    bg= (Rgb 10 18 31); panel=(Rgb 16 28 43); panel2=(Rgb 20 36 54)
    nav=(Rgb 12 23 38); ink=(Rgb 228 241 247); muted=(Rgb 157 179 196)
    cyan=(Rgb 42 224 234); dim=(Rgb 69 101 120); orange=(Rgb 245 173 70)
    red=(Rgb 253 116 123); green=(Rgb 83 223 175)
}
$script:Font = New-Object System.Drawing.Font('Segoe UI',10)
$script:FontSmall = New-Object System.Drawing.Font('Segoe UI',9)
$script:FontStrong = New-Object System.Drawing.Font('Segoe UI Semibold',11)
$script:FontTitle = New-Object System.Drawing.Font('Segoe UI Semibold',20)
$script:Selection = $null
$script:ActiveCategory = 'Alle'

function PathFor($entry) {
    if ($entry.mode -eq 'volume') { return $null }
    $rel = [string]$entry.path
    if (-not $rel -or [System.IO.Path]::IsPathRooted($rel)) { return $null }
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $script:Root ($rel.Replace('/','\'))))
    if (-not $candidate.StartsWith(($script:Root.TrimEnd('\') + '\'),[System.StringComparison]::OrdinalIgnoreCase)) { return $null }
    return $candidate
}
function BackupDrive {
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        try { if ($d.IsReady -and $d.VolumeLabel -eq 'BACKUPS') { return $d.RootDirectory.FullName } } catch {}
    }
    return $null
}
function HasEntry($entry) {
    if ($entry.mode -eq 'volume') { return [bool](BackupDrive) }
    $path = PathFor $entry
    return (($null -ne $path) -and (Test-Path -LiteralPath $path))
}
function MakeLabel($text,$x,$y,$w,$h,$font,$color,$parent) {
    $lab=New-Object System.Windows.Forms.Label
    $lab.Text=$text; $lab.Left=$x; $lab.Top=$y; $lab.Width=$w; $lab.Height=$h
    $lab.Font=$font; $lab.ForeColor=$color; $lab.BackColor=[System.Drawing.Color]::Transparent
    $parent.Controls.Add($lab); return $lab
}
function MakeBtn($text,$x,$y,$w,$h,$background,$foreground,$parent) {
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$text; $b.Left=$x; $b.Top=$y; $b.Width=$w; $b.Height=$h
    $b.Font=$script:Font; $b.BackColor=$background; $b.ForeColor=$foreground
    $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=1
    $b.FlatAppearance.BorderColor=$script:C.dim
    $b.Cursor=[System.Windows.Forms.Cursors]::Hand
    $parent.Controls.Add($b); return $b
}
function Notice($message,$caption='IT-Werkstatt Toolkit') {
    [System.Windows.Forms.MessageBox]::Show($form,$message,$caption,[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}
function ConfirmRisk($entry) {
    if ($entry.risk -eq 'normal') { return $true }
    $level = if ($entry.risk -eq 'danger') { 'HOHES RISIKO' } else { 'BITTE PRUEFEN' }
    $message = "$level`r`n`r`n$($entry.name)`r`n`r`n$($entry.note)`r`n`r`nProgramm wirklich starten?"
    $answer = [System.Windows.Forms.MessageBox]::Show($form,$message,'Sicherheitsabfrage',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    return ($answer -eq [System.Windows.Forms.DialogResult]::Yes)
}
function OpenDir($entry) {
    $path = if ($entry.mode -eq 'volume') { BackupDrive } else { PathFor $entry }
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { Notice 'Datei oder Ordner derzeit nicht vorhanden.'; return }
    $dir = if (Test-Path -LiteralPath $path -PathType Container) { $path } else { Split-Path -Path $path -Parent }
    try { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $dir + '"') -ErrorAction Stop }
    catch { Notice $_.Exception.Message 'Ordner konnte nicht geoeffnet werden' }
}
function RunTool($entry,[bool]$asAdmin=$false) {
    if (-not $entry) { return }
    if (-not (HasEntry $entry)) { Notice 'Dieses Werkzeug ist auf der T9 nicht vorhanden oder nicht eingerichtet.'; return }
    if ($entry.mode -in @('folder','volume')) { OpenDir $entry; return }
    $path = PathFor $entry
    if ($entry.mode -eq 'cli') {
        # Opening a terminal does NOT auto-run potentially destructive CLI programs.
        $dir = Split-Path -Path $path -Parent
        try { Start-Process -FilePath 'cmd.exe' -ArgumentList ('/K cd /d "' + $dir + '"') -WorkingDirectory $dir }
        catch { Notice $_.Exception.Message 'Konsole konnte nicht gestartet werden' }
        return
    }
    if (-not (ConfirmRisk $entry)) { return }
    $dir = Split-Path -Path $path -Parent
    try {
        if ($entry.mode -in @('ps1','ps1_email')) {
            if ($entry.mode -eq 'ps1_email') {
                $email = [Microsoft.VisualBasic.Interaction]::InputBox('Welche E-Mail-Adresse soll gesucht werden?','Edge-Konto-Diagnose','')
                if ([string]::IsNullOrWhiteSpace($email)) { return }
                # Restrict input to a conventional email address, to avoid argument injection.
                if ($email -notmatch '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') { Notice 'Bitte eine gueltige einfache E-Mail-Adresse eingeben.'; return }
                $args = '-NoProfile -NoExit -STA -File "' + $path + '" -TargetEmail "' + $email + '"'
            } else { $args = '-NoProfile -NoExit -STA -File "' + $path + '"' }
            if ($asAdmin) { Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WorkingDirectory $dir -Verb RunAs -ErrorAction Stop }
            else { Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WorkingDirectory $dir -ErrorAction Stop }
        } else {
            if ($asAdmin) { Start-Process -FilePath $path -WorkingDirectory $dir -Verb RunAs -ErrorAction Stop }
            else { Start-Process -FilePath $path -WorkingDirectory $dir -ErrorAction Stop }
        }
    }
    catch { Notice $_.Exception.Message 'Programmstart fehlgeschlagen' }
}

$form=New-Object System.Windows.Forms.Form
$form.Text='IT-WERKSTATT TOOLKIT | Portable Werkstatt'
$form.Size=New-Object System.Drawing.Size(1280,765)
$form.MinimumSize=New-Object System.Drawing.Size(1060,680)
$form.StartPosition='CenterScreen'
$form.BackColor=$script:C.bg; $form.ForeColor=$script:C.ink; $form.Font=$script:Font

# TableLayoutPanel nesting avoids Dock.Fill obscuring search or navigation panels.
$layout=New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock='Fill';$layout.RowCount=2;$layout.ColumnCount=1
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute,96)))
[void]$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,100)))
$form.Controls.Add($layout)
$header=New-Object System.Windows.Forms.Panel
$header.Dock='Fill'; $header.BackColor=$script:C.nav
$layout.Controls.Add($header,0,0)
$title=MakeLabel 'IT-WERKSTATT TOOLKIT' 25 13 560 42 $script:FontTitle $script:C.cyan $header
$subtitle=MakeLabel 'PORTABLE WERKSTATT  -  offline  /  Windows 10 & 11  |  Entwicklung: Nols' 27 59 700 23 $script:FontSmall $script:C.muted $header
$status=MakeLabel '' 820 29 425 25 $script:Font $script:C.green $header
$status.Anchor='Top,Right'; $status.TextAlign='MiddleRight'
$line=New-Object System.Windows.Forms.Panel
$line.BackColor=$script:C.cyan; $line.Height=2; $line.Dock='Bottom'; $header.Controls.Add($line)

$work=New-Object System.Windows.Forms.TableLayoutPanel
$work.Dock='Fill'; $work.ColumnCount=2; $work.RowCount=1
[void]$work.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,238)))
[void]$work.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,100)))
$layout.Controls.Add($work,0,1)
$nav=New-Object System.Windows.Forms.Panel
$nav.Dock='Fill'; $nav.BackColor=$script:C.nav
$work.Controls.Add($nav,0,0)
MakeLabel 'KATEGORIEN' 20 25 205 28 $script:FontStrong $script:C.muted $nav | Out-Null
$categoryList=New-Object System.Windows.Forms.ListBox
$categoryList.Left=15;$categoryList.Top=61;$categoryList.Width=208;$categoryList.Height=420
$categoryList.Anchor='Top,Left,Bottom';$categoryList.BorderStyle='None'
$categoryList.BackColor=$script:C.nav;$categoryList.ForeColor=$script:C.ink
$categoryList.Font=New-Object System.Drawing.Font('Segoe UI Semibold',10)
$categoryList.IntegralHeight=$false;$categoryList.ItemHeight=35
foreach ($cat in $script:Catalog.categories) { [void]$categoryList.Items.Add([string]$cat.label) }
$categoryList.SelectedIndex=0;$nav.Controls.Add($categoryList)

$content=New-Object System.Windows.Forms.TableLayoutPanel
$content.Dock='Fill';$content.BackColor=$script:C.bg;$content.RowCount=2;$content.ColumnCount=1
[void]$content.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute,82)))
[void]$content.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent,100)))
$work.Controls.Add($content,1,0)
$searchPanel=New-Object System.Windows.Forms.Panel
$searchPanel.Dock='Fill';$searchPanel.BackColor=$script:C.bg
$content.Controls.Add($searchPanel,0,0)
$searchLabel=MakeLabel 'WERKZEUG SUCHEN' 18 11 260 23 $script:FontStrong $script:C.muted $searchPanel
$search=New-Object System.Windows.Forms.TextBox
$search.Left=18; $search.Top=38; $search.Width=565; $search.Height=30
$search.Font=$script:Font; $search.BackColor=$script:C.panel2; $search.ForeColor=$script:C.ink
$search.BorderStyle='FixedSingle';$searchPanel.Controls.Add($search)
$search.Anchor='Top,Left,Right'

$body=New-Object System.Windows.Forms.TableLayoutPanel
$body.Dock='Fill'; $body.Padding=New-Object System.Windows.Forms.Padding(12,0,12,12)
$body.BackColor=$script:C.bg;$body.ColumnCount=2;$body.RowCount=1
$body.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,59))) | Out-Null
$body.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,41))) | Out-Null
$content.Controls.Add($body,0,1)

$list=New-Object System.Windows.Forms.ListView
$list.View='Details';$list.FullRowSelect=$true;$list.MultiSelect=$false
$list.HideSelection=$false;$list.GridLines=$false;$list.Dock='Fill'
$list.BackColor=$script:C.panel;$list.ForeColor=$script:C.ink
$list.Font=$script:FontSmall;$list.HeaderStyle='Nonclickable'
[void]$list.Columns.Add('WERKZEUG',242)
[void]$list.Columns.Add('TYP',100)
[void]$list.Columns.Add('STATUS',92)
[void]$list.Columns.Add('RISIKO',76)
$body.Controls.Add($list,0,0)
$details=New-Object System.Windows.Forms.Panel
$details.Dock='Fill'; $details.AutoScroll=$true; $details.Padding=New-Object System.Windows.Forms.Padding(12,12,0,0)
$details.BackColor=$script:C.panel2;$body.Controls.Add($details,1,0)
$detailName=MakeLabel 'Werkzeug auswaehlen' 17 14 345 48 $script:FontStrong $script:C.cyan $details
$detailName.Anchor='Top,Left,Right'
$detailKind=MakeLabel '' 17 64 345 30 $script:FontSmall $script:C.muted $details
$detailKind.Anchor='Top,Left,Right'
$detailText=New-Object System.Windows.Forms.TextBox
$detailText.Left=17;$detailText.Top=100;$detailText.Width=347;$detailText.Height=158
$detailText.Multiline=$true;$detailText.ReadOnly=$true;$detailText.ScrollBars='Vertical'
$detailText.BorderStyle='None';$detailText.BackColor=$script:C.panel2;$detailText.ForeColor=$script:C.ink
$detailText.Font=$script:Font;$detailText.Anchor='Top,Left,Right,Bottom'
$details.Controls.Add($detailText)
$pathTitle=MakeLabel 'RELATIVER PFAD' 17 262 345 23 $script:FontSmall $script:C.muted $details
$pathTitle.Anchor='Bottom,Left,Right'
$detailPath=New-Object System.Windows.Forms.TextBox
$detailPath.Left=17;$detailPath.Top=285;$detailPath.Width=345;$detailPath.Height=50
$detailPath.Multiline=$true;$detailPath.ReadOnly=$true;$detailPath.ScrollBars='Vertical'
$detailPath.BorderStyle='FixedSingle';$detailPath.BackColor=$script:C.panel;$detailPath.ForeColor=$script:C.ink
$detailPath.Font=$script:FontSmall;$detailPath.Anchor='Bottom,Left,Right'
$details.Controls.Add($detailPath)
$risk=MakeLabel '' 17 343 343 62 $script:FontSmall $script:C.orange $details
$risk.Anchor='Bottom,Left,Right'
$btnStart=MakeBtn 'STARTEN' 17 408 158 39 $script:C.cyan $script:C.bg $details
$btnStart.Anchor='Bottom,Left'
$btnAdmin=MakeBtn 'ALS ADMIN' 183 408 167 39 $script:C.panel $script:C.ink $details
$btnAdmin.Anchor='Bottom,Left,Right'
$btnFolder=MakeBtn 'ORDNER ANZEIGEN' 17 455 333 35 $script:C.panel $script:C.ink $details
$btnFolder.Anchor='Bottom,Left,Right'
$hint=MakeLabel 'Status: nur Dateien auf der T9. Terminal-Tools werden nicht automatisch ausgefuehrt.' 17 500 344 52 $script:FontSmall $script:C.muted $details
$hint.Anchor='Bottom,Left,Right'

function SelectedEntry {
  if ($list.SelectedItems.Count -eq 0) { return $null }
  return $list.SelectedItems[0].Tag
}
function ShowDetails {
    $entry=SelectedEntry
    $script:Selection=$entry
    if (-not $entry) { $detailName.Text='Werkzeug auswaehlen'; $detailKind.Text=''; $detailText.Text=''; $detailPath.Text=''; $risk.Text=''; $btnStart.Enabled=$false;$btnAdmin.Enabled=$false;$btnFolder.Enabled=$false;return }
    $exists=HasEntry $entry
    $detailName.Text=[string]$entry.name
    $detailKind.Text="Bereich: $($entry.category)    |    Admin: $($entry.admin)"
    $detailText.Text="$($entry.description)`r`n`r`nEINSATZ:`r`n$($entry.usage)`r`n`r`nHINWEIS:`r`n$($entry.note)"
    $detailPath.Text=[string]$entry.path
    if (-not $exists) { $risk.Text='NICHT VORHANDEN / NOCH NICHT EINGERICHTET'; $risk.ForeColor=$script:C.red }
    elseif ($entry.risk -eq 'danger') {$risk.Text='ACHTUNG: ERHOEHTES RISIKO - Sicherheitsabfrage vor Start';$risk.ForeColor=$script:C.red}
    elseif ($entry.risk -eq 'caution') {$risk.Text='HINWEIS: Vor dem Start Einsatzbedingungen pruefen';$risk.ForeColor=$script:C.orange}
    else {$risk.Text='BEREIT / NUR AUF ANKLICKEN';$risk.ForeColor=$script:C.green}
    $btnStart.Enabled=$exists;$btnFolder.Enabled=$exists
    $btnAdmin.Enabled=($exists -and $entry.mode -in @('exe','installer','ps1','ps1_email'))
    if ($entry.mode -eq 'cli') { $btnStart.Text='TERMINAL' }
    elseif ($entry.mode -eq 'installer') { $btnStart.Text='PAKET STARTEN' }
    elseif ($entry.mode -in @('folder','volume')) { $btnStart.Text='OEFFNEN' }
    else { $btnStart.Text='STARTEN' }
}
function RenderList {
    $query=$search.Text.Trim().ToLowerInvariant()
    $list.BeginUpdate(); $list.Items.Clear()
    foreach ($e in $script:Catalog.items) {
        if ($script:ActiveCategory -eq 'NurVorhanden' -and -not (HasEntry $e)) { continue }
        if ($script:ActiveCategory -notin @('Alle','NurVorhanden') -and [string]$e.category -ne $script:ActiveCategory) { continue }
        $hay=("$($e.name) $($e.category) $($e.description) $($e.usage) $($e.tags -join ' ')").ToLowerInvariant()
        if ($query -and -not $hay.Contains($query)) { continue }
        $exists=HasEntry $e
        $modeName = switch ([string]$e.mode) {
            'exe' {'Programm'}; 'installer' {'Setup/Paket'}; 'cli' {'CLI'}; 'volume' {'Partition'}; 'folder' {'Ordner'}; default {'PowerShell'}
        }
        $state=if ($exists) {'VORHANDEN'} else {'FEHLT'}
        $level=switch ([string]$e.risk) { 'danger' {'HOCH'}; 'caution' {'HINWEIS'}; default {'NORMAL'} }
        $row=New-Object System.Windows.Forms.ListViewItem([string]$e.name)
        [void]$row.SubItems.Add($modeName); [void]$row.SubItems.Add($state); [void]$row.SubItems.Add($level)
        $row.Tag=$e
        if (-not $exists) {$row.ForeColor=$script:C.dim}
        elseif ($e.risk -eq 'danger') {$row.ForeColor=$script:C.red}
        elseif ($e.risk -eq 'caution') {$row.ForeColor=$script:C.orange}
        [void]$list.Items.Add($row)
    }
    $list.EndUpdate()
    $status.Text="$($list.Items.Count) Eintraege   |   USB: $([System.IO.Path]::GetPathRoot($script:Root))"
    if ($list.Items.Count -gt 0) { $list.Items[0].Selected=$true }
    ShowDetails
}
$categoryList.Add_SelectedIndexChanged({
    $idx=$categoryList.SelectedIndex
    if ($idx -ge 0) { $script:ActiveCategory=[string]$script:Catalog.categories[$idx].id; RenderList }
})
$search.Add_TextChanged({ RenderList })
$list.Add_SelectedIndexChanged({ ShowDetails })
$list.Add_DoubleClick({ $e=SelectedEntry; if ($e) {RunTool $e $false} })
$btnStart.Add_Click({$e=SelectedEntry; if($e){RunTool $e $false}})
$btnAdmin.Add_Click({$e=SelectedEntry; if($e){RunTool $e $true}})
$btnFolder.Add_Click({$e=SelectedEntry; if($e){OpenDir $e}})
$form.Add_Shown({
    if (-not ((Test-Path -LiteralPath (Join-Path $script:Root 'ISO')) -and (Test-Path -LiteralPath (Join-Path $script:Root 'ventoy\ventoy.json')))) {
        Notice 'Die erwartete Ventoy-Struktur wurde nicht gefunden. Lege den gesamten Ordner NOLS-Toolkit direkt im Stammverzeichnis der Ventoy-Partition ab. Fehlende Programmdateien werden entsprechend markiert.'
    }
    RenderList
})
[void][System.Windows.Forms.Application]::Run($form)
