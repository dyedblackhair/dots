#!/usr/bin/env bash
# Small rofi power menu used by the waybar "custom/power" module.

set -uo pipefail
export PATH="/usr/local/bin:/usr/bin:/usr/sbin:/bin:$PATH"

choice="$(
    printf '%s\n' "Log out" "Suspend" "Reboot" "Shut down" \
        | rofi -dmenu -i -p "Power" -no-custom
)" || exit 0

case "$choice" in
    "Log out") mmsg dispatch quit ;;
    "Suspend") systemctl suspend ;;
    "Reboot") systemctl reboot ;;
    "Shut down") systemctl poweroff ;;
    *) exit 0 ;;
esac
