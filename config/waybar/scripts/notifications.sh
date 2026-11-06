#!/usr/bin/env bash
# Waybar custom module: notification count + Do Not Disturb state from dunst.
# Prints a single JSON line understood by waybar's "return-type": "json".

set -uo pipefail

PATH="/usr/local/bin:/usr/bin:/usr/sbin:/bin:$PATH"
DUNSTCTL="$(command -v dunstctl || true)"

# Font Awesome glyphs wrapped in Pango markup; another family is listed as a
# fallback so a system with Font Awesome 7 installed keeps working.
fa_icon() {
    printf "<span font_family='Font Awesome 6 Free, Font Awesome 7 Free' font_weight='900'>%b</span>" "$1"
}

bell="$(fa_icon '\uf0f3')"
bell_slash="$(fa_icon '\uf1f6')"

if [[ -z "$DUNSTCTL" ]]; then
    printf '{"text":"%s","alt":"none","class":"none","tooltip":"dunstctl not found"}\n' "$bell"
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
        text="$bell_slash $count"
        class="dnd-notification"
    else
        text="$bell_slash"
        class="dnd-none"
    fi
else
    state="off"
    if ((count > 0)); then
        text="$bell $count"
        class="notification"
    else
        text="$bell"
        class="none"
    fi
fi

tooltip="Notifications: $count"
tooltip+="\\nDo Not Disturb: $state"

printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' \
    "$text" "$class" "$class" "$tooltip"
