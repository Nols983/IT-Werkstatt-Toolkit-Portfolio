"""Non-Windows, read-only checks for the Phase 3 build assets."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1] / "winpe" / "builder"

class WinPEBuildAssetsTests(unittest.TestCase):
    def test_scripts_exist(self):
        for name in ("BUILD-RECOVERY.ps1", "BUILD-RECOVERY.cmd", "README.md", "startup/startnet.cmd", "startup/NOLS-Autostart.cmd", "startup/NOLS-Preflight.cmd"):
            self.assertTrue((ROOT / name).is_file(), name)

    def test_batch_arguments_do_not_quote_options(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text()
        self.assertIn("if ($a -in @('amd64', '/ISO'))", text)

    def test_startnet_calls_proven_autostart(self):
        data = (ROOT / "startup/startnet.cmd").read_bytes()
        self.assertIn(b"wpeinit", data)
        self.assertIn(b"NOLS-Autostart.cmd", data)
        self.assertTrue(data.endswith(b"\r\n"))

    def test_expected_optional_components(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text()
        for name in ("WinPE-WMI", "WinPE-Scripting", "WinPE-SecureStartup", "Set-InputLocale:0407:00000407", "cscript.exe"):
            self.assertIn(name, text)

    def test_only_iso_build_not_usb_media(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text()
        self.assertIn("'/ISO'", text)
        self.assertNotIn("'/UFD'", text)
        self.assertNotIn("'/F'", text)
        self.assertNotIn("Format-Volume", text)
        self.assertNotIn("Clear-Disk", text)

    def test_default_is_read_only(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text()
        self.assertIn("if (-not $Build)", text)
        self.assertIn("NUR VORSCHAU", text)
        self.assertIn("$mounted", text)

    # Regressionstests fuer die im Windows-Praxistest behobenen Fehler.
    # Diese Pruefungen analysieren nur Quelltext: kein ADK-/Boot-Laufzeittest.
    def test_components_use_add_windows_package(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text(encoding="utf-8-sig")
        self.assertRegex(text, r"(?m)^\s*Add-WindowsPackage\s+-Path\s+\$ImagePath\s+-PackagePath\s+\$CabPath\s+-NoRestart\b")
        self.assertIn("Add-WinPEComponent $mountDir (Join-Path $ocDir ($oc+'.cab'))", text)
        self.assertIn("Add-WinPEComponent $mountDir (Join-Path $ocDir ('en-us\\'+$oc+'_en-us.cab'))", text)

    def test_adk_batch_does_not_reuse_dism_argument_helper(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text(encoding="utf-8-sig")
        # Der ADK-Batch-Aufruf braucht seinen eigenen cmd.exe-Start mit quoted Pfad.
        start = text.index("function Invoke-AdkBatch(")
        end = text.index("\n}", start)
        body = text[start:end]
        self.assertRegex(body, r"(?m)^\s*& \"\$env:SystemRoot\\System32\\cmd\.exe\" /d /c")
        self.assertNotRegex(body, r"(?m)^\s*Invoke-Native\b")

    def test_locale_options_are_two_separate_dism_arguments(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text(encoding="utf-8-sig")
        # Verhindert die in v0.2.3 beobachtete PowerShell-Operatorbindung.
        self.assertRegex(text, r"(?m)^\s*\$intlImageArg\s*=\s*'/Image:'\s*\+\s*\$mountDir\s*$")
        self.assertRegex(text, r"(?m)^\s*\$intlLocaleArg\s*=\s*'/Set-InputLocale:0407:00000407'\s*$")
        self.assertRegex(text, r"(?m)^\s*Invoke-Native\s+.*@\(\$intlImageArg,\s*\$intlLocaleArg\)")

    def test_mount_cleanup_and_no_usb_target(self):
        text = (ROOT / "BUILD-RECOVERY.ps1").read_text(encoding="utf-8-sig")
        self.assertIn("if ($rootDrive -ine $systemDrive", text)
        self.assertIn("if ([System.IO.Directory]::Exists($runDir))", text)
        self.assertRegex(text, r"(?m)^\s*Invoke-Native\s+.*'/Unmount-Image'.*'/Commit'")
        self.assertRegex(text, r"(?m)^\s*& .*dism\.exe.*'/MountDir:'\+\$mountDir.* /Discard")

if __name__ == '__main__':
    unittest.main()
