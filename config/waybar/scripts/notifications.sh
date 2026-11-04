#!/usr/bin/env bash
# Waybar custom module: notification count + Do Not Disturb state from dunst.
# Prints a single JSON line understood by waybar's "return-type": "json".

set -uo pipefail

PATH="/usr/local/bin:/usr/bin:/usr/sbin:/bin:$PATH"
DUNSTCTL="$(command -v dunstctl || true)"

if [[ -z "$DUNSTCTL" ]]; then
    printf '{"text":"󰂜","alt":"none","class":"none","tooltip":"dunstctl not found"}\n'
    exit 0
fi

waiting="$("$DUNSTCTL" count waiting 2>/dev/null)" || waiting=0
displayed="$("$DUNSTCTL" count displayed 2>/dev/null)" || displayed=0
paused="$("$DUNSTCTL" is-paused 2>/dev/null)" || paused=false

[[ "$waiting" =~ ^[0-9]+$ ]] || waiting=0
[[ "$displayed" =~ ^[0-9]+$ ]] || displayed=0
count=$((waiting + displayed))

if [[ "$paused" == "true" ]]; then
    state="on"
    if ((count > 0)); then
        text="󰂛 $count"
        class="dnd-notification"
    else
        text="󰂛"
        class="dnd-none"
    fi
else
    state="off"
    if ((count > 0)); then
        text="󰂚 $count"
        class="notification"
    else
        text="󰂜"
        class="none"
    fi
fi

tooltip="Notifications: $count"
tooltip+="\\nDo Not Disturb: $state"

printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' \
    "$text" "$class" "$class" "$tooltip"
