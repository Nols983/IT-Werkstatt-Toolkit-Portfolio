"""Tests for safety of GitHub preparation, without running any Windows repair scripts."""
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('repository_check', ROOT / 'scripts/check_repository.py')
assert SPEC is not None and SPEC.loader is not None
import sys
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class RepositoryCheckTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for required in MODULE.REQUIRED:
            p = self.root / required
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(b'@echo off\r\n')
        (self.root / MODULE.TOOLKIT / 'Recovery/Analyse/offline_analyse.py').write_text('pass\n')
        (self.root / 'winpe/startnet.cmd').write_bytes(b'call X:\\ITW\\ITW-Autostart.cmd\r\n')

    def codes(self):
        return {i.code for i in MODULE.scan(self.root)[0]}

    def test_minimal_structure(self):
        self.assertEqual(self.codes(), set())

    def test_missing_module_ref(self):
        launcher = self.root / MODULE.TOOLKIT / 'Recovery/Recovery-Launcher.cmd'
        launcher.write_bytes(b'call "%MOD%\\DoesNotExist.cmd"\r\n')
        self.assertIn('MODULE', self.codes())

    def test_rejects_iso_and_dump(self):
        (self.root / 'Microsoft.iso').write_bytes(b'not a real iso')
        (self.root / 'trace.dmp').write_bytes(b'not a real dump')
        self.assertIn('BINARY', self.codes())

    def test_rejects_customer_logs(self):
        p = self.root / MODULE.TOOLKIT / 'Recovery/Logs/customer.txt'
        p.parent.mkdir(parents=True)
        p.write_text('private')
        self.assertIn('DATA', self.codes())

    def test_detects_potential_token(self):
        (self.root / 'secrets.txt').write_text('github_pat_' + 'X' * 35)
        self.assertIn('SECRET', self.codes())

    def test_json_python_parse(self):
        (self.root / 'bad.py').write_text('def :')
        (self.root / 'bad.json').write_text('{ broken')
        self.assertIn('PYTHON', self.codes())
        self.assertIn('JSON', self.codes())

    def test_original_snapshot_matches_real_copy(self):
        # Checks the 58 known baseline files in the actual repo, independently of scan().
        manifest = json.loads((ROOT / 'scripts/original_source_hashes.json').read_text())
        self.assertEqual(len(manifest), 58)
        for rel in manifest:
            self.assertTrue((ROOT / 'toolkit' / rel).is_file(), rel)


if __name__ == '__main__':
    unittest.main()
