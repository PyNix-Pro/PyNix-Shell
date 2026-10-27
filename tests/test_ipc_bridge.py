#!/usr/bin/env python3
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BRIDGE = ROOT / "scripts" / "pynix-ipc.sh"


class IpcBridgeTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.bin_dir = Path(self.temp_dir.name) / "bin"
        self.bin_dir.mkdir()
        bash = shutil.which("bash")
        if bash:
            (self.bin_dir / "bash").symlink_to(bash)
        self.capture = Path(self.temp_dir.name) / "arguments"

    def add_cli(self, name):
        cli = self.bin_dir / name
        cli.write_text(
            "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$PYNIX_IPC_TEST_CAPTURE\"\n",
            encoding="utf-8",
        )
        cli.chmod(0o755)

    def run_bridge(self, *args):
        environment = os.environ.copy()
        environment["PATH"] = str(self.bin_dir)
        environment["PYNIX_IPC_TEST_CAPTURE"] = str(self.capture)
        return subprocess.run(
            [str(BRIDGE), *args],
            env=environment,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_allowed_command_is_forwarded_to_qs_ipc(self):
        self.add_cli("qs")
        result = self.run_bridge("open-control-center")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.capture.read_text(encoding="utf-8").splitlines(),
            ["ipc", "call", "pynix", "command", "open-control-center"],
        )

    def test_quickshell_cli_fallback_is_supported(self):
        self.add_cli("quickshell")
        result = self.run_bridge("open-launcher")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.capture.read_text(encoding="utf-8").splitlines(),
            ["ipc", "call", "pynix", "command", "open-launcher"],
        )

    def test_invalid_or_missing_command_is_rejected_without_forwarding(self):
        self.add_cli("qs")
        result = self.run_bridge("not-a-command")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Unsupported PyNix Shell command", result.stderr)
        self.assertFalse(self.capture.exists())

        result = self.run_bridge()
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.capture.exists())

    def test_missing_quickshell_cli_is_reported(self):
        result = self.run_bridge("open-settings")
        self.assertEqual(result.returncode, 127)
        self.assertIn("Neither qs nor quickshell", result.stderr)


if __name__ == "__main__":
    unittest.main()
