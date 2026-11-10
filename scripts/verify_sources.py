#!/usr/bin/env python3
"""Verify the 58 byte-identical restored toolkit source files; read-only."""
import hashlib
import json
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
expected = json.loads((repo / 'scripts' / 'original_source_hashes.json').read_text(encoding='utf-8'))
failed = []
for rel, digest in sorted(expected.items()):
    p = repo / 'toolkit' / rel
    actual = hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else '(missing)'
    if actual != digest:
        failed.append((rel, actual))
print(f'SHA-256: {len(expected)-len(failed)}/{len(expected)} Originaldateien stimmen ueberein.')
for rel, actual in failed:
    print(f'ABWEICHUNG: {rel}: {actual}')
raise SystemExit(1 if failed else 0)
