#!/usr/bin/env python3
"""NOLS v2.4.1: read-only, evidence-based offline analysis of WinPE event exports.

WinPE's ``wevtutil /uni:false /f:xml`` can emit single-byte Windows-1252
characters despite no XML encoding declaration. Parse them as text, not as
unconditionally UTF-8 encoded XML bytes. Avoid claims about BSOD culprits.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

NS = {'e': 'http://schemas.microsoft.com/win/2004/08/events/event'}
EVENT_TAG = '{http://schemas.microsoft.com/win/2004/08/events/event}Event'
MAX_EVENTS = {'DISK': 80, 'STOR': 80, 'NTFS': 80, 'WHEA': 80,
              'BUGCHECK': 60, 'KERNEL_PNP': 60, 'DIENSTE': 60}
DEVICE_PATTERN = re.compile(
    r'\\Device\\(?:HarddiskVolume(?:ShadowCopy)?\d+|Harddisk\d+|RaidPort\d+|NVMe[^\s<]+)'
    r'|\\\\\.\\PhysicalDrive\d+', re.IGNORECASE)


def parse_xml(path: Path, preferred: str = 'auto'):
    """Return (root, chosen_encoding, error). Never silently replace data."""
    try:
        raw = path.read_bytes()
    except OSError as exc:
        return None, None, str(exc)
    if not raw.strip():
        return None, None, 'XML-Datei ist leer (kein Nachweis fuer 0 Ereignisse)'
    if preferred != 'auto':
        encodings = (preferred,)
    elif raw.startswith((b'\xff\xfe', b'\xfe\xff')):
        encodings = ('utf-16',)
    else:
        # Observed in WinPE XML logs: bytes E4/FC for German umlauts (CP1252).
        encodings = ('utf-8-sig', 'cp1252', 'cp850')
    problems = []
    for enc in encodings:
        try:
            txt = raw.decode(enc)
            return ET.fromstring(txt), enc, None
        except (UnicodeError, ET.ParseError, LookupError) as exc:
            problems.append(f'{enc}: {exc}')
    return None, None, '; '.join(problems)


def event_list(path: Path, group: str, encoding: str = 'auto'):
    root, source_encoding, err = parse_xml(path, encoding)
    if err:
        return [], source_encoding, err
    nodes = ([root] if root.tag == EVENT_TAG else root.findall('.//e:Event', NS))
    events = []
    for node in nodes:
        sysdata = node.find('e:System', NS)
        if sysdata is None:
            continue
        provider = sysdata.find('e:Provider', NS)
        eid = sysdata.find('e:EventID', NS)
        level = sysdata.find('e:Level', NS)
        stamp = sysdata.find('e:TimeCreated', NS)
        if stamp is None or not stamp.get('SystemTime'):
            continue
        try:
            dt = datetime.fromisoformat(stamp.get('SystemTime').replace('Z', '+00:00'))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            dt = dt.astimezone(timezone.utc)
        except ValueError:
            continue
        eventdata = []
        for data in node.findall('e:EventData/e:Data', NS):
            val = (data.text or '').strip()
            eventdata.append((data.get('Name') or '', val))
        lookup = {key.casefold(): val for key, val in eventdata if key}
        content = ' '.join(v for k, v in eventdata)
        devices = sorted(set(DEVICE_PATTERN.findall(content)), key=str.casefold)
        events.append({'time': dt, 'group': group,
                       'provider': provider.get('Name', '?') if provider is not None else '?',
                       'id': (eid.text or '?') if eid is not None else '?',
                       'level': (level.text or '?') if level is not None else '?',
                       'data': eventdata, 'fields': lookup, 'devices': devices})
    return events, source_encoding, None


def read_group(folder: Path, group: str, encoding: str):
    path = folder/'EventXML'/f'{group}.xml'
    if not path.is_file():
        return [], None, 'keine XML-Datei'
    events, codec, err = event_list(path, group.split('_', 1)[0], encoding)
    errorfile = path.with_suffix('.err.txt')
    if errorfile.is_file() and errorfile.stat().st_size > 0:
        # A nonempty error sidecar means the query may have failed/been partial.
        return events, codec, 'wevtutil-Fehlerdatei ist nicht leer'
    return events, codec, err


def ntfs_class(event):
    """Conservative classification, no assumptions that ID 98 is damage."""
    eid = event['id']
    if eid in ('55', '140'):
        return 'PRUEFEN'
    if eid == '98':
        state = event['fields'].get('corruptionactionstate', '').lower()
        if event['level'] == '4' and state in ('0', '0x0', ''):
            return 'INFO'
        return 'UNKLAR'
    return 'UNKLAR'


def time_label(event):
    return event['time'].isoformat(timespec='seconds')


def short(value: str, limit=160):
    line = re.sub(r'\s+', ' ', value.strip())
    return line if len(line) <= limit else line[:limit-1] + '…'


def correlate(events, limit=15, minutes=5):
    ordered = sorted(events, key=lambda ev: ev['time'])
    clusters = []
    used = set()
    window = timedelta(minutes=minutes)
    for index, first in enumerate(ordered):
        if index in used:
            continue
        in_window = [j for j in range(index, len(ordered))
                     if timedelta() <= ordered[j]['time']-first['time'] <= window]
        if len({ordered[j]['group'] for j in in_window}) < 2:
            continue
        subset = [ordered[j] for j in in_window]
        clusters.append((subset[0]['time'], subset[-1]['time'], Counter(e['group'] for e in subset)))
        used.update(in_window)
        if len(clusters) >= limit:
            break
    return clusters


def storage(folder: Path, encoding='auto'):
    parts = [
        'IT-WERKSTATT TOOLKIT v2.4.1 – STORAGE-NACHAUSWERTUNG (Linux/PC)', '='*70,
        'Quelle: WinPE-XML, maximal 80 neueste Treffer je Ereignisgruppe.',
        'Uhrzeit der Ereignisse: UTC. Kein automatischer Nachweis eines Hardwaredefekts.',
        'Ereignisse koennen auch von bereits vergangenen Problemen stammen.', ''
    ]
    all_events = []
    eligible = []
    any_error = False
    for group in ('DISK', 'STOR', 'NTFS', 'WHEA'):
        events, codec, err = read_group(folder, f'{group}_ALL', encoding)
        if err:
            any_error = True
            parts.append(f'[OFFEN] {group}: {err}')
            continue
        all_events.extend(events)
        limit_note = ' (STICHPROBENLIMIT ERREICHT, weitere moeglich)' if len(events) >= MAX_EVENTS[group] else ''
        parts.append(f'[BEFUND] {group}: {len(events)} Ereignisse{limit_note} [XML: {codec}]')
        if events:
            parts.append(f'  Zeitspanne: {time_label(min(events, key=lambda e:e["time"]))}'
                         f' bis {time_label(max(events, key=lambda e:e["time"]))}')
        if group != 'NTFS':
            eligible.extend(events)
            continue
        categories = Counter(ntfs_class(e) for e in events)
        parts.append(f'  NTFS-Unterteilung: pruefen={categories["PRUEFEN"]};'
                     f' Info={categories["INFO"]}; unklar={categories["UNKLAR"]}')
        parts.append('  ID 98 mit Level 4 ist nicht automatisch eine Dateisystembeschaedigung.')
        flagged = [e for e in events if ntfs_class(e) != 'INFO']
        eligible.extend(flagged)
        if flagged:
            parts.append('  Relevante/unklare NTFS-Eintraege (neueste zuerst):')
            for event in sorted(flagged, key=lambda e:e['time'], reverse=True)[:10]:
                fields = event['fields']
                device = fields.get('devicename') or fields.get('drivename') or 'Geraet nicht angegeben'
                parts.append(f'    {time_label(event)} | ID {event["id"]} | Level {event["level"]}'
                             f' | {short(device,90)}')
                if fields.get('description'):
                    parts.append(f'      Beschreibung: {short(fields["description"],170)}')
                if 'shadowcopy' in device.lower():
                    parts.append('      [HINWEIS] Schattenkopie; kein Nachweis fuer Schaden am aktuell gemounteten Volume.')
    parts += ['', 'MOEGLICHE ZEITLICHE NAEHE: verschiedene Gruppen innerhalb 5 Minuten', '-'*70,
              'NTFS-98-Infoeintraege werden dafuer NICHT als Fehlerindiz verwendet.']
    clusters = correlate(eligible)
    if clusters:
        for start, end, counts in clusters:
            parts.append(f'{start.isoformat()} bis {end.isoformat()}: '
                         +', '.join(f'{k}={v}' for k, v in sorted(counts.items())))
    elif any_error:
        parts.append('[OFFEN] Nicht alle Gruppen auswertbar; keine vollstaendige Korrelationsaussage.')
    else:
        parts.append('Keine gruppenuebergreifenden Zeitfenster in der erfassten Stichprobe.')
    devices = Counter(d for event in all_events for d in event['devices'])
    parts += ['', 'GERAETEBEZEICHNER (OHNE SICHERE ZUORDNUNG ZU DISKPART)', '-'*70]
    if devices:
        for device, count in devices.most_common(15):
            parts.append(f'  {short(device,120)}: {count} Nennungen')
    else:
        parts.append('Keine eindeutig auslesbaren Geraetebezeichner in EventData.')
    parts += ['', 'WICHTIGE GRENZEN:',
              '- Die ALL-Abfragen koennen aeltere Ereignisse abschneiden; 0 bedeutet nur in Stichprobe 0.',
              '- ID 55/140 sind Pruefhinweise; ID 98 kann eine normale Pruefung dokumentieren.',
              '- Ein Event auf einer Volume-Schattenkopie bedeutet nicht automatisch Fehler auf C:.',
              '- Ereignisnaehe beweist keine gemeinsame Ursache. Bei I/O-Verdacht zuerst Backup.',
              '- DISM, DiskPart und SMART koennen ohne weitere Daten keine konkrete SSD beweisen.']
    return '\n'.join(parts)+'\n'


def bsod(folder: Path, encoding='auto'):
    parts = ['IT-WERKSTATT TOOLKIT v2.4.1 – BSOD-/TREIBER-NACHAUSWERTUNG (Linux/PC)', '='*70,
             'Nur gespeicherte Ereignisse und Treiberinventar. Kein Dumpdebugger.',
             'SCM-Dienstereignisse sind KEIN Nachweis fuer einen schuldigen Treiber.', '']
    for group in ('BUGCHECK', 'KERNEL_PNP', 'DIENSTE'):
        events, codec, err = read_group(folder, group, encoding)
        if err:
            parts.append(f'[OFFEN] {group}: {err}')
            continue
        clipped = ' (STICHPROBENLIMIT ERREICHT)' if len(events) >= MAX_EVENTS[group] else ''
        parts.append(f'[BEFUND] {group}: {len(events)} Ereignisse{clipped} [XML: {codec}]')
        if group == 'DIENSTE':
            ids = Counter(e['id'] for e in events)
            parts.append('  Ereignis-IDs: ' + (', '.join(f'{k}={v}' for k,v in sorted(ids.items())) or 'keine'))
            services = defaultdict(list)
            for event in events:
                service_name = event['fields'].get('param1', '')
                if not service_name:
                    service_name = '(kein Dienstname in EventData)'
                services[(event['id'], short(service_name, 100))].append(event)
            if services:
                parts.append('  Wiederkehrende Dienstnamen (ID / Anzahl / zuletzt UTC):')
                for (eid, name), group_events in sorted(services.items(),
                        key=lambda kv:(-len(kv[1]), kv[0][0], kv[0][1]))[:12]:
                    latest = max(group_events, key=lambda e:e['time'])
                    parts.append(f'    ID {eid} | {len(group_events):>2}x | '
                                 f'{time_label(latest)} | {name}')
                parts.append('  Das sind Ereignisse von Diensten/Komponenten, nicht bewiesene BSOD-Verursacher.')
        else:
            for event in sorted(events, key=lambda e:e['time'], reverse=True)[:6]:
                parts.append(f'  {time_label(event)} | {event["provider"]} | ID {event["id"]}')
                if group == 'BUGCHECK':
                    fields = event['fields']
                    for k,v in list(fields.items()):
                        if 'bugcheck' in k or 'param' in k or 'code' in k:
                            parts.append(f'    {k}: {short(v,100)}')
    inf = folder/'20_Treiber_Drittanbieter.txt'
    if inf.is_file():
        raw = inf.read_bytes()
        try:
            content = raw.decode('utf-8-sig')
        except UnicodeDecodeError:
            content = raw.decode('cp850', 'replace')
        oems = {s.casefold() for s in re.findall(r'\boem\d+\.inf\b', content, re.IGNORECASE)}
        parts.append(f'Inventar: {len(oems)} verschiedene OEM-INF-Namen gefunden.')
        parts.append('Achtung: OEM-INF ist ein TreiberPAKET, nicht zwingend ein aktiver .sys-Treiber.')
    else:
        parts.append('[OFFEN] Treiberinventar fehlt.')
    dump_report = folder/'10_Dumps.txt'
    if dump_report.is_file():
        parts.append('Dump-Fundstellen wurden in 10_Dumps.txt dokumentiert (keine Dump-Inhaltsanalyse).')
    else:
        parts.append('[OFFEN] 10_Dumps.txt fehlt.')
    parts += ['', 'Nae chster Schritt nur bei echtem BSOD-Fall: Minidump auf geeignetem Windows-PC',
              'mit WinDbg/CDB und passenden Symbolen auswerten (!analyze -v).',
              'Keine automatische Treiber-Deinstallation oder Schuldzuweisung.',
              'Stichproben sind begrenzt; fehlende Treffer schliessen Fehler nicht aus.']
    return '\n'.join(parts).replace('Nae chster','Naechster')+'\n'


def main():
    parser = argparse.ArgumentParser(description='IT-Werkstatt Offline-Auswertung (nur gespeicherte Logs)')
    parser.add_argument('ordner', type=Path, help='Ordner SPEICHER_* oder BSOD_TREIBER_*')
    parser.add_argument('--mode', choices=('storage','bsod'), required=True)
    parser.add_argument('--xml-encoding', default='auto',
                        choices=('auto','utf-8','cp1252','cp850','utf-16'),
                        help='auto: UTF-8, dann Windows-1252; ggf. cp850 manuell')
    args = parser.parse_args()
    folder = args.ordner.expanduser().resolve()
    if not folder.is_dir():
        parser.error('Ordner nicht vorhanden')
    text = storage(folder, args.xml_encoding) if args.mode=='storage' else bsod(folder, args.xml_encoding)
    output = folder/('98_Speicher_Korrelation.txt' if args.mode=='storage' else '98_BSOD_Auswertung.txt')
    output.write_text(text, encoding='utf-8')
    print(text)
    print('Bericht:', output)
    return 0

if __name__=='__main__':
    sys.exit(main())
