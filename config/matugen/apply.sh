#!/usr/bin/env bash
# Regenerate all desktop themes from the current wallpaper using matugen.
# Always uses the dark palette.

set -uo pipefail

export PATH="$HOME/.local/bin:$PATH"

CONFIG_DIR="$HOME/.config/matugen"
STATE_FILE="$CONFIG_DIR/current-wallpaper"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/matugen"
LOG_FILE="$LOG_DIR/theme.log"
FALLBACK_COLOR="#7aa2f7"

mkdir -p "$LOG_DIR"
printf '\n=== %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" >>"$LOG_FILE"

log() {
    printf '%s\n' "$*" >>"$LOG_FILE"
}

if [[ ! -f "$STATE_FILE" ]]; then
    log "No wallpaper state file at $STATE_FILE"
    exit 1
fi

image="$(cat "$STATE_FILE")"
if [[ ! -f "$image" ]]; then
    log "Wallpaper not found: $image"
    notify-send "Matugen" "Wallpaper not found: $image" 2>/dev/null || true
    exit 1
fi

matugen_bin="$(command -v matugen || true)"
if [[ -z "$matugen_bin" ]]; then
    matugen_bin="$HOME/.local/bin/matugen"
fi
if [[ ! -x "$matugen_bin" ]]; then
    log "matugen binary not found"
    notify-send "Matugen" "matugen binary not found" 2>/dev/null || true
    exit 1
fi

# Make sure output directories exist.
mkdir -p \
    "$HOME/.config/kitty" \
    "$HOME/.config/waybar" \
    "$HOME/.config/rofi" \
    "$HOME/.config/gtk-3.0" \
    "$HOME/.config/gtk-4.0" \
    "$HOME/.config/mango" \
    "$HOME/.config/dunst"

log "Generating dark palette from: $image"

if ! "$matugen_bin" image "$image" \
        --mode dark \
        --type scheme-tonal-spot \
        --config "$CONFIG_DIR/config.toml" >>"$LOG_FILE" 2>&1; then
    log "matugen image failed; falling back to $FALLBACK_COLOR"
    notify-send "Matugen" "Failed to read wallpaper colors, using fallback" 2>/dev/null || true

    if ! "$matugen_bin" color hex "$FALLBACK_COLOR" \
            --mode dark \
            --type scheme-tonal-spot \
            --config "$CONFIG_DIR/config.toml" >>"$LOG_FILE" 2>&1; then
        log "matugen fallback failed"
        notify-send "Matugen" "Failed to generate theme" 2>/dev/null || true
        exit 1
    fi
fi

# Force dark mode for GTK / libadwaita apps. Toggle the preference so
# already-running libadwaita apps notice the change.
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' >/dev/null 2>&1 || true
    current_scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
    if [[ "$current_scheme" == "'prefer-dark'" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' >/dev/null 2>&1 || true
    fi
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
fi

# Reload running applications that support live config reloads.
pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true
pkill -SIGUSR2 -x waybar >/dev/null 2>&1 || true
mmsg dispatch reload_config >/dev/null 2>&1 || true
dunstctl reload >/dev/null 2>&1 || true

log "Theme applied."
