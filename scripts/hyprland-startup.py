#!/usr/bin/env python3
"""Safely detect and manage PyNix Shell startup in a Hyprland config."""

from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

BEGIN = "# >>> PYNIX-SHELL MANAGED STARTUP BEGIN >>>"
END = "# <<< PYNIX-SHELL MANAGED STARTUP END <<<"
KEYBINDINGS = (
    ("SUPER", "F10", "open-control-center"),
    ("SUPER_SHIFT", "F10", "close-control-center"),
    ("SUPER", "F11", "expand-island"),
    ("SUPER_SHIFT", "F11", "collapse-island"),
    ("SUPER", "F9", "open-settings"),
    ("SUPER", "F8", "open-theme-switcher"),
    ("SUPER", "F7", "open-launcher"),
)


class IntegrationError(Exception):
    pass


def config_home() -> Path:
    value = os.environ.get("XDG_CONFIG_HOME")
    return Path(value).expanduser() if value else Path.home() / ".config"


def read_config(path: Path) -> str:
    if path.is_symlink():
        raise IntegrationError(f"Refusing to follow a symlinked Hyprland config: {path}")
    if not path.is_file():
        raise IntegrationError(f"Hyprland config is not a regular file: {path}")
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise IntegrationError(f"Cannot read Hyprland config {path}: {exc}") from exc


def detect_format(text: str) -> str:
    active_lines = "\n".join(
        line.split("#", 1)[0]
        for line in text.splitlines()
        if line.strip() and not line.lstrip().startswith("--")
    )
    lua = bool(
        re.search(r"\bhl\.(?:config|on|bind|env|exec_cmd)\s*\(", active_lines)
        or re.search(r"^\s*(?:local|return)\s+", active_lines, re.MULTILINE)
        or re.search(r"\brequire\s*\(", active_lines)
    )
    hyprlang = bool(
        re.search(r"^\s*(?:exec-once|exec|source|monitor|bind|env)\s*=", active_lines, re.MULTILINE)
        or re.search(r"^\s*[A-Za-z_][\w:-]*\s*\{\s*$", active_lines, re.MULTILINE)
        or re.search(r"^\s*\$[\w-]+\s*=", active_lines, re.MULTILINE)
    )

    if lua == hyprlang:
        if lua:
            raise IntegrationError("Config contains conflicting Lua and hyprlang syntax; refusing automatic edits.")
        raise IntegrationError("Config format could not be identified from its contents.")
    return "lua" if lua else "hyprlang"


def hyprland_version() -> tuple[int, int]:
    executable = shutil.which("Hyprland")
    if not executable:
        raise IntegrationError("Hyprland executable 'Hyprland' is unavailable; cannot verify config compatibility.")
    try:
        result = subprocess.run(
            [executable, "--version"],
            check=True,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise IntegrationError(f"Could not inspect the installed Hyprland version: {exc}") from exc
    match = re.search(r"\b(\d+)\.(\d+)(?:\.\d+)?\b", result.stdout + "\n" + result.stderr)
    if not match:
        raise IntegrationError("Could not parse the installed Hyprland version.")
    return int(match.group(1)), int(match.group(2))


def verify_version_compatibility(fmt: str, version: tuple[int, int]) -> None:
    if fmt == "lua" and version < (0, 55):
        raise IntegrationError(
            f"Hyprland {version[0]}.{version[1]} predates Lua configuration support; "
            "use a hyprlang config or upgrade the guest."
        )
    if fmt == "hyprlang" and version >= (0, 55):
        raise IntegrationError(
            f"Hyprland {version[0]}.{version[1]} uses Lua configuration. "
            "The hyprlang startup hook is supported only with Hyprland versions before 0.55."
        )


def validate_config_location(path: Path) -> Path:
    root = config_home() / "hypr"
    expanded = path.expanduser()
    if "\n" in str(expanded) or "\t" in str(expanded):
        raise IntegrationError("Hyprland config paths may not contain tabs or newlines.")
    if not expanded.is_absolute():
        raise IntegrationError(f"Hyprland config path must be absolute: {expanded}")
    if root.is_symlink():
        raise IntegrationError(f"Refusing to edit a symlinked Hyprland config directory: {root}")
    if expanded.is_symlink():
        raise IntegrationError(f"Refusing to follow a symlinked Hyprland config: {expanded}")
    parent = expanded.parent
    while parent != root and parent != parent.parent:
        if parent.is_symlink():
            raise IntegrationError(f"Refusing to traverse a symlinked config directory: {parent}")
        parent = parent.parent
    resolved_root = root.resolve()
    resolved_path = expanded.resolve(strict=True)
    try:
        resolved_path.relative_to(resolved_root)
    except ValueError as exc:
        raise IntegrationError(f"Refusing to modify a config outside {root}: {expanded}") from exc
    if not resolved_path.is_file():
        raise IntegrationError(f"Hyprland config must be a regular, non-symlink file: {expanded}")
    if resolved_path.stat().st_uid != os.getuid():
        raise IntegrationError(f"Hyprland config is not owned by the current user: {resolved_path}")
    if not os.access(resolved_path, os.W_OK):
        raise IntegrationError(f"Hyprland config is not writable by the current user: {resolved_path}")
    return resolved_path


def detect_config(explicit_path: Path | None = None) -> tuple[Path, str, tuple[int, int]]:
    version = hyprland_version()
    if explicit_path is not None:
        candidates = [validate_config_location(explicit_path)]
    else:
        root = config_home() / "hypr"
        candidates = [
            path
            for path in (root / "hyprland.lua", root / "hyprland.conf")
            if path.exists()
        ]
        if not candidates:
            raise IntegrationError(f"No standard Hyprland config found under {root}.")
        if len(candidates) > 1:
            preferred = root / ("hyprland.lua" if version >= (0, 55) else "hyprland.conf")
            if preferred not in candidates:
                raise IntegrationError(
                    "Multiple Hyprland config candidates exist and the version-default config is absent. "
                    "Select the active file explicitly with --hyprland-config."
                )
            candidates = [preferred]
        candidates = [validate_config_location(candidates[0])]

    fmt = detect_format(read_config(candidates[0]))
    verify_version_compatibility(fmt, version)
    return candidates[0], fmt, version


def line_ending(text: str) -> str:
    return "\r\n" if text.count("\r\n") > text.count("\n") / 2 else "\n"


def _lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def block_for(
    fmt: str,
    launcher: Path,
    eol: str,
    added_newline: bool,
    keybindings: bool = False,
) -> str:
    helper = launcher.parent / "pynix-ipc.sh"
    lines = [
        BEGIN,
        f"# pynix-added-leading-newline: {1 if added_newline else 0}",
        f"# pynix-keybindings: {1 if keybindings else 0}",
    ]
    if fmt == "lua":
        command = _lua_string(shlex.quote(str(launcher)))
        lines.extend([
            'hl.on("hyprland.start", function()',
            f"    hl.exec_cmd({command})",
            "end)",
        ])
        if keybindings:
            for modifiers, key, action in KEYBINDINGS:
                lua_command = shlex.quote(str(helper)) + " " + action
                lines.append(
                    f"hl.bind({_lua_string(modifiers.replace('_', ' + ') + ' + ' + key)}, "
                    f"hl.dsp.exec_cmd({_lua_string(lua_command)}))"
                )
    else:
        lines.append(f"exec-once = {shlex.quote(str(launcher))}")
        if keybindings:
            command = shlex.quote(str(helper))
            for modifiers, key, action in KEYBINDINGS:
                lines.append(f"bind = {modifiers}, {key}, exec, {command} {action}")
    lines.append(END)
    return eol.join(lines)


def replace_atomically(path: Path, text: str, mode: int) -> None:
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.pynix-", dir=path.parent)
    temp_path = Path(temp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temp_path, stat.S_IMODE(mode))
        os.replace(temp_path, path)
    except OSError:
        try:
            temp_path.unlink(missing_ok=True)
        finally:
            raise


def install(config: Path, launcher: Path, backup_dir: Path, keybindings: bool = False) -> None:
    config = validate_config_location(config)
    launcher = launcher.expanduser().resolve()
    if "\n" in str(launcher) or "\t" in str(launcher):
        raise IntegrationError("Startup launcher paths may not contain tabs or newlines.")
    if not launcher.is_file() or not os.access(launcher, os.X_OK):
        raise IntegrationError(f"Startup launcher is missing or not executable: {launcher}")
    helper = launcher.parent / "pynix-ipc.sh"
    if keybindings and (not helper.is_file() or not os.access(helper, os.X_OK)):
        raise IntegrationError(f"IPC command helper is missing or not executable: {helper}")
    original_text = read_config(config)
    fmt = detect_format(original_text)
    version = hyprland_version()
    verify_version_compatibility(fmt, version)

    begin_count, end_count = original_text.count(BEGIN), original_text.count(END)
    if begin_count != end_count or begin_count > 1:
        raise IntegrationError("Managed startup markers are incomplete or duplicated; refusing to edit config.")

    mode = config.stat().st_mode
    eol = line_ending(original_text)
    text = original_text
    if begin_count == 1:
        text, _ = remove_block(text, eol)
    added_newline = bool(text) and not text.endswith(("\n", "\r"))
    prefix = eol if added_newline else ""
    updated = text + prefix + block_for(fmt, launcher, eol, added_newline, keybindings) + eol
    if updated == original_text:
        print(f"PyNix Shell startup already configured in {config}")
        return

    for parent in (backup_dir, *backup_dir.parents):
        if parent.exists() and parent.is_symlink():
            raise IntegrationError(f"Refusing to create a backup through a symlink: {parent}")
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup = backup_dir / f"{config.name}.pynix-{os.getpid()}.backup"
    suffix = 1
    while backup.exists():
        backup = backup_dir / f"{config.name}.pynix-{os.getpid()}-{suffix}.backup"
        suffix += 1
    shutil.copy2(config, backup)
    if read_config(config) != original_text:
        raise IntegrationError("Hyprland config changed while preparing integration; backup retained and edit aborted.")
    replace_atomically(config, updated, mode)
    print(f"Backed up Hyprland config to {backup}")
    print(f"Added {fmt} startup integration to {config}")


def remove_block(text: str, eol: str | None = None) -> tuple[str, bool]:
    begin_count, end_count = text.count(BEGIN), text.count(END)
    if begin_count == 0 and end_count == 0:
        return text, False
    if begin_count != 1 or end_count != 1:
        raise IntegrationError("Managed startup markers are incomplete or duplicated; refusing removal.")

    start = text.index(BEGIN)
    end = text.index(END, start) + len(END)
    if text.index(END) < start:
        raise IntegrationError("Managed startup markers are out of order; refusing removal.")
    body = text[start:end]
    metadata = re.search(r"pynix-added-leading-newline:\s*([01])", body)
    if not metadata:
        raise IntegrationError("Managed startup metadata is missing; refusing removal.")
    launcher_path = (config_home() / "pynix-shell" / "scripts" / "start-shell.sh").resolve()
    ending = eol or line_ending(text)
    legacy_lua = (
        f"{BEGIN}{ending}# pynix-added-leading-newline: {metadata.group(1)}{ending}"
        f'hl.on("hyprland.start", function(){ending}'
        f"    hl.exec_cmd({_lua_string(shlex.quote(str(launcher_path)))}){ending}"
        f"end){ending}{END}"
    )
    legacy_hyprlang = (
        f"{BEGIN}{ending}# pynix-added-leading-newline: {metadata.group(1)}{ending}"
        f"exec-once = {shlex.quote(str(launcher_path))}{ending}{END}"
    )
    valid_bodies = {legacy_lua, legacy_hyprlang}
    for fmt in ("lua", "hyprlang"):
        for has_bindings in (False, True):
            valid_bodies.add(
                block_for(fmt, launcher_path, ending, metadata.group(1) == "1", has_bindings)
            )
    if body not in valid_bodies:
        raise IntegrationError("Managed startup block was modified; refusing to remove user-edited content.")
    prefix_start = start
    if metadata.group(1) == "1":
        ending = eol or line_ending(text)
        if text[:start].endswith(ending):
            prefix_start -= len(ending)

    after = text[end:]
    if after.startswith("\r\n"):
        end += 2
    elif after.startswith("\n"):
        end += 1
    return text[:prefix_start] + text[end:], True


def remove(config: Path) -> None:
    config = validate_config_location(config)
    text = read_config(config)
    eol = line_ending(text)
    updated, changed = remove_block(text, eol)
    if not changed:
        print(f"No PyNix Shell startup block found in {config}")
        return
    replace_atomically(config, updated, config.stat().st_mode)
    print(f"Removed only the PyNix Shell startup block from {config}")


def main() -> int:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    detect_parser = commands.add_parser("detect")
    detect_parser.add_argument("--config", type=Path)
    install_parser = commands.add_parser("install")
    install_parser.add_argument("--config", type=Path, required=True)
    install_parser.add_argument("--launcher", type=Path, required=True)
    install_parser.add_argument("--backup-dir", type=Path, required=True)
    install_parser.add_argument("--keybindings", action="store_true")
    remove_parser = commands.add_parser("remove")
    remove_parser.add_argument("--config", type=Path, required=True)
    args = parser.parse_args()

    try:
        if args.command == "detect":
            path, fmt, version = detect_config(args.config)
            print(f"{fmt}\t{path}\t{version[0]}.{version[1]}")
        elif args.command == "install":
            install(args.config, args.launcher, args.backup_dir, args.keybindings)
        elif args.command == "remove":
            remove(args.config)
    except (IntegrationError, OSError) as exc:
        print(f"PyNix Shell Hyprland integration error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
