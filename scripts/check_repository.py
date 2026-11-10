#!/usr/bin/env python3
"""Read-only repository preflight for IT-Werkstatt Toolkit (Python stdlib)."""
from __future__ import annotations

import argparse
import ast
import json
import re
from dataclasses import dataclass
from pathlib import Path

TOOLKIT = Path('toolkit/NOLS-Toolkit')
REQUIRED = (
    TOOLKIT / 'START-RECOVERY.cmd',
    TOOLKIT / 'Recovery/Recovery-Launcher.cmd',
    TOOLKIT / 'Recovery/Modules/ChooseDrive.cmd',
    TOOLKIT / 'Recovery/Modules/WriteTargetGuard.cmd',
    TOOLKIT / 'Recovery/Modules/HardwareInventur.cmd',
    TOOLKIT / 'Recovery/Modules/HardwareInventur.vbs',
    TOOLKIT / 'Recovery/Modules/TimeCheck.cmd',
    TOOLKIT / 'Recovery/Analyse/offline_analyse.py',
    Path('winpe/startnet.cmd'),
    Path('winpe/ITW-Autostart.cmd'),
)
FORBIDDEN_SUFFIXES = {
    '.iso', '.wim', '.esd', '.img', '.vhd', '.vhdx', '.dmp', '.evtx',
    '.pfx', '.p12', '.pem', '.key', '.crt', '.sqlite', '.db', '.zip', '.7z',
    '.exe', '.msi', '.dll', '.sys', '.log', '.bak', '.pyc',
}
FORBIDDEN_DIRS = {'logs', 'backups', 'scratch', 'eventxml', 'tools', '__pycache__', '.git'}
# Patterns with very low false positive rates. This is NOT an exhaustive secret scanner.
CREDENTIAL_PATTERNS = {
    'private key header': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    'GitHub token': re.compile(rb'\b(?:ghp_|gho_|ghu_|ghs_|ghr_|github_pat_)[A-Za-z0-9_]{16,}'),
    'AWS access key': re.compile(rb'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
}
# String literals known to refer to the standalone Modules directory.
MODULE_PATTERN = re.compile(rb'(?:%MOD%|!MOD!)\\([a-zA-Z0-9_.-]+\.cmd)', re.I)


@dataclass(frozen=True)
class Issue:
    code: str
    message: str


def scan(root: Path) -> tuple[list[Issue], dict[str, int]]:
    root = root.resolve()
    issues: list[Issue] = []
    stats = {'files': 0, 'python': 0, 'json': 0, 'cmd': 0, 'module_references': 0}
    if not (root / TOOLKIT).is_dir():
        return [Issue('STRUCTURE', f'Quellcode fehlt: {TOOLKIT}')], stats

    for required in REQUIRED:
        if not (root / required).is_file():
            issues.append(Issue('MISSING', f'Pflichtdatei fehlt: {required}'))

    seen: dict[str, str] = {}
    for path in sorted(root.rglob('*')):
        rel = path.relative_to(root)
        # .git is not part of the deliverable; ignore local git metadata entirely.
        if '.git' in rel.parts or '__pycache__' in rel.parts or '.pytest_cache' in rel.parts:
            continue
        if path.is_symlink():
            issues.append(Issue('SYMLINK', f'Symlink statt regulärer Datei: {rel}'))
            continue
        if not path.is_file():
            continue
        stats['files'] += 1
        folded = str(rel).casefold()
        if folded in seen and seen[folded] != str(rel):
            issues.append(Issue('CASE', f'Windows-Dateinamenskollision: {rel} / {seen[folded]}'))
        seen[folded] = str(rel)
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            issues.append(Issue('BINARY', f'Nicht für GitHub vorgesehen: {rel}'))
        if any(p.lower() in FORBIDDEN_DIRS for p in rel.parts[:-1]):
            issues.append(Issue('DATA', f'Laufzeit-/Drittanbieterverzeichnis im Repository: {rel}'))
        if path.stat().st_size > 4_000_000:
            issues.append(Issue('LARGE', f'Unerwartet große Quelldatei: {rel}'))
        if path.suffix.lower() not in {'.cmd', '.vbs', '.ps1', '.py', '.json', '.html', '.txt', '.md', '.yml', '.yaml', '.sh'}:
            continue
        data = path.read_bytes()
        for name, pattern in CREDENTIAL_PATTERNS.items():
            if pattern.search(data):
                issues.append(Issue('SECRET', f'Möglicher {name} in: {rel}'))
        if path.suffix.lower() == '.py':
            stats['python'] += 1
            try:
                ast.parse(data.decode('utf-8-sig'), filename=str(rel))
            except (SyntaxError, UnicodeError) as exc:
                issues.append(Issue('PYTHON', f'Python-Syntax/Encoding: {rel}: {exc}'))
        elif path.suffix.lower() == '.json':
            stats['json'] += 1
            try:
                json.loads(data.decode('utf-8-sig'))
            except (ValueError, UnicodeError) as exc:
                issues.append(Issue('JSON', f'JSON fehlerhaft: {rel}: {exc}'))
        elif path.suffix.lower() == '.cmd':
            stats['cmd'] += 1
            # Never re-encode original CMD sources: preserve CP850/CRLF byte-for-byte.
            for target in set(MODULE_PATTERN.findall(data)):
                stats['module_references'] += 1
                target_path = root / TOOLKIT / 'Recovery' / 'Modules' / target.decode('ascii')
                if not target_path.is_file():
                    issues.append(Issue('MODULE', f'Zielmodul fehlt: {rel} -> {target.decode("ascii")}'))

    # The local repo contains only draft WinPE startup files, not Microsoft binaries.
    startnet = root / 'winpe/startnet.cmd'
    if startnet.is_file() and b'ITW-Autostart.cmd' not in startnet.read_bytes():
        issues.append(Issue('STARTUP', 'WinPE-Entwurf verweist nicht auf ITW-Autostart.cmd'))
    return issues, stats


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    issues, stats = scan(args.root)
    print('IT-WERKSTATT - REPOSITORY-PREFLIGHT (nur lesend)')
    for key, value in stats.items():
        print(f'  {key}: {value}')
    if issues:
        print(f'FEHLER ({len(issues)}):')
        for issue in issues:
            print(f'  [{issue.code}] {issue.message}')
        return 1
    print('OK: Keine Probleme in den automatisierten Pflichtprüfungen gefunden.')
    print('Hinweis: Kein WinPE-Laufzeittest und keine vollständige Geheimnis-/Lizenzprüfung.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
