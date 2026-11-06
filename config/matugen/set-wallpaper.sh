#!/usr/bin/env bash
# Set the wallpaper, remember it, and regenerate the matugen dark theme.
#
# Usage:
#   set-wallpaper.sh <image>   set a specific image
#   set-wallpaper.sh --pick    choose an image with rofi
#   set-wallpaper.sh --random  choose a random image from ~/Pictures/wallpaper
#   set-wallpaper.sh --restore restore the last wallpaper (used at login)
#   set-wallpaper.sh --apply   only regenerate the theme for the current wallpaper

set -uo pipefail

export PATH="$HOME/.local/bin:$PATH"

CONFIG_DIR="$HOME/.config/matugen"
STATE_FILE="$CONFIG_DIR/current-wallpaper"
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/11.jpg"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/matugen"
LOG_FILE="$LOG_DIR/theme.log"

mkdir -p "$LOG_DIR" "$WALLPAPER_DIR"

log() {
    printf '%s\n' "$*" >>"$LOG_FILE"
}

image_extensions=(-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp')

case "${1:---restore}" in
    --apply)
        exec "$CONFIG_DIR/apply.sh"
        ;;
    --pick)
        if ! command -v rofi >/dev/null 2>&1; then
            log "rofi not found, cannot pick wallpaper"
            exit 1
        fi
        choice="$(
            find "$WALLPAPER_DIR" -maxdepth 1 -type f \( "${image_extensions[@]}" \) -printf '%f\n' \
                | sort \
                | rofi -dmenu -i -p 'Wallpaper'
        )" || exit 0
        [[ -n "$choice" ]] || exit 0
        image="$WALLPAPER_DIR/$choice"
        ;;
    --random)
        image="$(
            find "$WALLPAPER_DIR" -maxdepth 1 -type f \( "${image_extensions[@]}" \) -print0 \
                | shuf -z -n 1 \
                | tr -d '\0'
        )"
        [[ -n "$image" ]] || { log "No wallpapers in $WALLPAPER_DIR"; exit 1; }
        ;;
    --restore|"")
        image=""
        if [[ -f "$STATE_FILE" ]]; then
            image="$(cat "$STATE_FILE")"
        fi
        if [[ -z "$image" || ! -f "$image" ]]; then
            image="$DEFAULT_WALLPAPER"
        fi
        ;;
    --help|-h)
        sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    -*)
        printf 'Unknown option: %s\n' "$1" >&2
        exit 2
        ;;
    *)
        image="$1"
        ;;
esac

if [[ ! -f "$image" ]]; then
    log "Wallpaper does not exist: $image"
    notify-send "Wallpaper" "File not found: $image" 2>/dev/null || true
    exit 1
fi

image="$(realpath "$image")"
printf '%s\n' "$image" >"$STATE_FILE"
log "Wallpaper selected: $image"

# Restart swaybg so the new image is actually displayed.
pkill -x swaybg >/dev/null 2>&1 || true
for _ in {1..40}; do
    pgrep -x swaybg >/dev/null 2>&1 || break
    sleep 0.05
done
setsid swaybg -i "$image" >/dev/null 2>&1 &
disown 2>/dev/null || true

"$CONFIG_DIR/apply.sh"
