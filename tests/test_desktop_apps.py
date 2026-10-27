#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parent.parent
MODULE_SPEC = importlib.util.spec_from_file_location(
    "desktop_apps", ROOT / "scripts" / "desktop-apps.py"
)
desktop_apps = importlib.util.module_from_spec(MODULE_SPEC)
assert MODULE_SPEC.loader is not None
MODULE_SPEC.loader.exec_module(desktop_apps)


class DesktopAppsTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name) / "applications"
        self.root.mkdir()

    def tearDown(self):
        self.temp_dir.cleanup()

    def write_entry(self, relative_path, body):
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")
        return path

    def test_lists_visible_entries_and_applies_desktop_rules(self):
        self.write_entry(
            "nested/editor.desktop",
            "[Desktop Entry]\nType=Application\nName=Code Editor\n"
            "Comment=Edit source\nTryExec=editor\nExec=editor %F\n",
        )
        self.write_entry(
            "hidden.desktop",
            "[Desktop Entry]\nType=Application\nName=Hidden\nHidden=true\n",
        )
        self.write_entry(
            "nodisplay.desktop",
            "[Desktop Entry]\nType=Application\nName=Internal\nNoDisplay=true\n",
        )
        self.write_entry(
            "only-gnome.desktop",
            "[Desktop Entry]\nType=Application\nName=GNOME Only\nOnlyShowIn=GNOME;\n",
        )
        self.write_entry(
            "bad-bool.desktop",
            "[Desktop Entry]\nType=Application\nName=Malformed Flag\nHidden=maybe\n",
        )
        apps = desktop_apps.list_applications(
            [self.root],
            desktop_names={"Hyprland"},
            executable_check=lambda command: "/usr/bin/editor" if command == "editor" else None,
        )
        self.assertEqual(
            [item["desktopId"] for item in apps],
            ["nested-editor.desktop", "bad-bool.desktop"],
        )

    def test_user_hidden_entry_masks_system_entry(self):
        system_root = self.root / "system"
        user_root = self.root / "user"
        system_root.mkdir()
        user_root.mkdir()
        (system_root / "browser.desktop").write_text(
            "[Desktop Entry]\nType=Application\nName=Browser\n",
            encoding="utf-8",
        )
        (user_root / "browser.desktop").write_text(
            "[Desktop Entry]\nType=Application\nName=Browser\nHidden=true\n",
            encoding="utf-8",
        )
        self.assertEqual(desktop_apps.list_applications(
            [user_root, system_root], executable_check=lambda _: "/bin/true"
        ), [])

    def test_invalid_and_missing_application_ids_are_refused(self):
        with mock.patch.object(desktop_apps, "list_applications", return_value=[]):
            with self.assertRaises(ValueError):
                desktop_apps.launch_application("../bad.desktop", launcher="/bin/true")
            with self.assertRaises(ValueError):
                desktop_apps.launch_application("missing.desktop", launcher="/bin/true")

    def test_launch_uses_argv_without_shell_and_reports_missing_provider(self):
        entry = {"desktopId": "editor.desktop", "name": "Editor", "icon": "", "comment": ""}
        with mock.patch.object(desktop_apps, "list_applications", return_value=[entry]):
            with mock.patch.object(
                desktop_apps.subprocess,
                "run",
                return_value=desktop_apps.subprocess.CompletedProcess(
                    ["gtk-launch", "editor.desktop"], 0, "", ""
                ),
            ) as run:
                desktop_apps.launch_application("editor.desktop", launcher="/usr/bin/gtk-launch")
                run.assert_called_once_with(
                    ["/usr/bin/gtk-launch", "editor.desktop"],
                    stdin=desktop_apps.subprocess.DEVNULL,
                    stdout=desktop_apps.subprocess.PIPE,
                    stderr=desktop_apps.subprocess.PIPE,
                    text=True,
                    timeout=15,
                    check=False,
                )
            with mock.patch.object(desktop_apps.shutil, "which", return_value=None):
                with self.assertRaisesRegex(RuntimeError, "No GTK desktop-entry launcher"):
                    desktop_apps.launch_application("editor.desktop")

    def test_nonzero_launcher_exit_is_reported(self):
        entry = {"desktopId": "editor.desktop", "name": "Editor", "icon": "", "comment": ""}
        with mock.patch.object(desktop_apps, "list_applications", return_value=[entry]):
            with mock.patch.object(
                desktop_apps.subprocess,
                "run",
                return_value=desktop_apps.subprocess.CompletedProcess(
                    ["gtk-launch", "editor.desktop"], 1, "", "launch failed"
                ),
            ):
                with self.assertRaisesRegex(RuntimeError, "launch failed"):
                    desktop_apps.launch_application("editor.desktop", launcher="/usr/bin/gtk-launch")

    def test_launcher_timeout_is_reported(self):
        entry = {"desktopId": "editor.desktop", "name": "Editor", "icon": "", "comment": ""}
        with mock.patch.object(desktop_apps, "list_applications", return_value=[entry]):
            with mock.patch.object(
                desktop_apps.subprocess,
                "run",
                side_effect=desktop_apps.subprocess.TimeoutExpired("gtk-launch", 15),
            ) as run:
                with self.assertRaises(desktop_apps.subprocess.TimeoutExpired):
                    desktop_apps.launch_application("editor.desktop", launcher="/usr/bin/gtk-launch")
                self.assertEqual(run.call_args.kwargs["timeout"], 15)


if __name__ == "__main__":
    unittest.main()
