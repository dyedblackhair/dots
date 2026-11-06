#!/usr/bin/env python3
"""Waybar dropdown tray: SNI items and quick actions in a rofi menu.

Uses busctl from systemd, so it does not depend on PyGObject.
"""

import os
import shlex
import shutil
import subprocess
import sys

WATCHER_BUS = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
ITEM_IFACE = "org.kde.StatusNotifierItem"
SEPARATOR = "──────────────"
TIMEOUT = 2


def busctl(*args):
    try:
        result = subprocess.run(
            ["busctl", "--user", *args],
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def parse_typed(text):
    """Return the value part of a `busctl` typed output line."""
    try:
        parts = shlex.split(text)
    except ValueError:
        return []
    return parts[1:] if parts else []


def get_property(service, path, name):
    values = parse_typed(busctl("get-property", service, path, ITEM_IFACE, name))
    return values[0] if values else ""


def get_tray_items():
    values = parse_typed(
        busctl(
            "get-property",
            WATCHER_BUS,
            WATCHER_PATH,
            WATCHER_BUS,
            "RegisteredStatusNotifierItems",
        )
    )
    # First value is the array length, the rest are item references.
    if values:
        values = values[1:]

    items = []
    for reference in values:
        service, separator, path = reference.partition("/")
        if not separator:
            continue
        path = "/" + path
        title = (
            get_property(service, path, "Title")
            or get_property(service, path, "Id")
            or service
        )
        items.append((title, service, path))
    return items


def activate_item(service, path):
    for method in ("Activate", "ContextMenu", "SecondaryActivate"):
        result = subprocess.run(
            ["busctl", "--user", "call", service, path, ITEM_IFACE, method, "ii", "0", "0"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=TIMEOUT,
        )
        if result.returncode == 0:
            return True
    return False


def build_entries():
    entries = []
    for title, service, path in get_tray_items():
        entries.append((title, ("tray", service, path)))

    if entries:
        entries.append((SEPARATOR, ("noop",)))

    entries.extend(
        [
            ("Сеть — nmtui", ("cmd", ["kitty", "-e", "nmtui"])),
            ("Звук — pavucontrol", ("cmd", ["pavucontrol"])),
            ("Уведомления — DND", ("cmd", ["dunstctl", "set-paused", "toggle"])),
            ("Заблокировать экран", ("cmd", ["swaylock", "-f", "-c", "000000"])),
            (
                "Меню питания",
                ("cmd", [os.path.expanduser("~/.config/waybar/scripts/power-menu.sh")]),
            ),
        ]
    )
    return entries


def unique_labels(entries):
    seen = {}
    lines = []
    actions = {}

    for label, action in entries:
        count = seen.get(label, 0) + 1
        seen[label] = count
        if count > 1:
            label = f"{label} ({count})"
        lines.append(label)
        actions[label] = action

    return lines, actions


def main():
    lines, actions = unique_labels(build_entries())

    if os.environ.get("TRAY_MENU_DRY"):
        print("\n".join(lines))
        return 0

    rofi = shutil.which("rofi")
    if not rofi:
        print("rofi not found", file=sys.stderr)
        return 1

    result = subprocess.run(
        [rofi, "-dmenu", "-i", "-p", "Меню", "-no-custom"],
        input="\n".join(lines) + "\n",
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        return 0

    action = actions.get(result.stdout.strip())
    if not action or action[0] == "noop":
        return 0

    if action[0] == "tray":
        _, service, path = action
        activate_item(service, path)
    elif action[0] == "cmd":
        subprocess.Popen(
            action[1],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
