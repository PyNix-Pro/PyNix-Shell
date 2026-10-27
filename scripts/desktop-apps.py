#!/usr/bin/env python3
"""List desktop applications and launch them through the desktop entry system."""

from __future__ import annotations

import argparse
import configparser
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Callable


def data_roots(environment: dict[str, str] | None = None) -> list[Path]:
    env = environment or os.environ
    home = Path(env.get("HOME", str(Path.home())))
    data_home = Path(env.get("XDG_DATA_HOME", str(home / ".local/share")))
    data_dirs = env.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    roots = [data_home, *(Path(item) for item in data_dirs.split(":") if item)]
    return list(dict.fromkeys(root / "applications" for root in roots))


def _read_desktop_file(path: Path) -> configparser.SectionProxy | None:
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    try:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            parser.read_file(handle)
    except (OSError, configparser.Error, UnicodeError):
        return None
    if not parser.has_section("Desktop Entry"):
        return None
    return parser["Desktop Entry"]


def _desktop_bool(entry: configparser.SectionProxy, key: str) -> bool:
    try:
        return entry.getboolean(key, fallback=False)
    except ValueError:
        return False


def list_applications(
    roots: list[Path] | None = None,
    desktop_names: set[str] | None = None,
    executable_check: Callable[[str], str | None] = shutil.which,
) -> list[dict[str, str]]:
    desktop_names = desktop_names or {
        value for value in os.environ.get("XDG_CURRENT_DESKTOP", "").split(":") if value
    }
    by_id: dict[str, dict[str, str] | None] = {}

    for root in reversed(roots if roots is not None else data_roots()):
        if not root.is_dir():
            continue
        for directory, dirnames, filenames in os.walk(root):
            dirnames.sort()
            for filename in sorted(filenames):
                if not filename.endswith(".desktop"):
                    continue
                path = Path(directory) / filename
                relative_id = path.relative_to(root).as_posix().replace("/", "-")
                if relative_id.startswith("-"):
                    continue
                entry = _read_desktop_file(path)
                if entry is None:
                    continue
                if entry.get("Type", "Application") != "Application":
                    by_id[relative_id] = None
                    continue
                if _desktop_bool(entry, "Hidden"):
                    by_id[relative_id] = None
                    continue
                if _desktop_bool(entry, "NoDisplay"):
                    by_id[relative_id] = None
                    continue
                only_show_in = {value for value in entry.get("OnlyShowIn", "").split(";") if value}
                not_show_in = {value for value in entry.get("NotShowIn", "").split(";") if value}
                if only_show_in and not desktop_names.intersection(only_show_in):
                    by_id[relative_id] = None
                    continue
                if desktop_names.intersection(not_show_in):
                    by_id[relative_id] = None
                    continue
                try_exec = entry.get("TryExec", "").strip()
                if try_exec and executable_check(try_exec) is None:
                    by_id[relative_id] = None
                    continue
                name = entry.get("Name", "").strip()
                if not name:
                    continue
                by_id[relative_id] = {
                    "desktopId": relative_id,
                    "name": name,
                    "icon": entry.get("Icon", "").strip(),
                    "comment": entry.get("Comment", "").strip(),
                }

    return sorted(
        (entry for entry in by_id.values() if entry is not None),
        key=lambda entry: (entry["name"].casefold(), entry["desktopId"]),
    )


def launch_application(desktop_id: str, launcher: str | None = None) -> None:
    if (not desktop_id.endswith(".desktop") or desktop_id.startswith("-") or
            "/" in desktop_id or "\n" in desktop_id or "\r" in desktop_id):
        raise ValueError("Invalid desktop application identifier.")
    available = {entry["desktopId"] for entry in list_applications()}
    if desktop_id not in available:
        raise ValueError("The selected desktop application is no longer available.")
    executable = launcher or shutil.which("gtk-launch") or shutil.which("gtk4-launch")
    if not executable:
        raise RuntimeError("No GTK desktop-entry launcher (gtk-launch or gtk4-launch) is available.")
    completed = subprocess.run(
        [executable, desktop_id],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=15,
        check=False,
    )
    if completed.returncode != 0:
        details = completed.stderr.strip()
        raise RuntimeError(details or "The desktop-entry launcher returned a failure status.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="action", required=True)
    subparsers.add_parser("list")
    launch_parser = subparsers.add_parser("launch")
    launch_parser.add_argument("desktop_id")
    args = parser.parse_args(argv)

    if args.action == "list":
        print(json.dumps({
            "applications": list_applications(),
            "launcherAvailable": any(shutil.which(name) for name in ("gtk-launch", "gtk4-launch")),
        }, ensure_ascii=False))
        return 0

    try:
        launch_application(args.desktop_id)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
