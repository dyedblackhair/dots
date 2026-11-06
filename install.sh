#!/usr/bin/env bash
# ============================================================================
#  Dotfiles installer
#  MangoWC · Waybar · Kitty · Rofi · Dunst · Cava · Matugen · Zsh/Oh My Zsh
#
#  Usage:
#    ./install.sh                 # symlink configs + install packages
#    ./install.sh --copy          # copy configs instead of symlinking
#    ./install.sh --no-packages   # only deploy config files
#    ./install.sh --apps          # also install optional desktop apps
#    ./install.sh --dry-run       # show what would happen
#    ./install.sh --uninstall     # remove symlinks created by this script
# ============================================================================
set -Eeuo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES/config"
HOME_SRC="$DOTFILES/home"
FALLBACK_SRC="$DOTFILES/fallbacks"
WALLPAPER_SRC="$DOTFILES/wallpapers"
USER_HOME="${HOME:?HOME is not set}"

MODE="link"          # link | copy
DO_PACKAGES=1
DO_APPS=0
DO_OMZ=1
DO_CHSH=1
DO_THEME=1
DRY_RUN=0
UNINSTALL=0
BACKUP_DIR="$USER_HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BACKUP_CREATED=0

# ---------------------------------------------------------------- output ----
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
    C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
    C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

log()  { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s!!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%sxx%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

run() {
    if (( DRY_RUN )); then
        printf '   [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

usage() {
    cat <<'EOF'
Dotfiles installer — MangoWC · Waybar · Kitty · Rofi · Dunst · Cava · Zsh

Usage:
  ./install.sh                 symlink configs + install packages
  ./install.sh --copy          copy configs instead of symlinking
  ./install.sh --no-packages   only deploy config files
  ./install.sh --apps          also install optional desktop apps
  ./install.sh --dry-run       show what would happen
  ./install.sh --uninstall     remove symlinks created by this script

Options:
  -c, --copy          copy files instead of symlinking
      --no-packages   do not install system packages
      --apps          also install optional apps (browser, editor, Spotify…)
      --no-oh-my-zsh  do not install Oh My Zsh and its plugins
      --no-chsh       do not change the login shell
      --no-theme      do not generate the matugen theme
      --dry-run       print actions without changing anything
      --uninstall     remove symlinks that point into this repository
  -h, --help          show this help

Configs are symlinked by default, so editing a file in the repository
(or in ~/.config, which is the same file) immediately affects the system.
Files containing @HOME@ are rendered as real files instead of symlinks.
EOF
}

# ---------------------------------------------------------------- helpers ---
read_list() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    awk '!/^[[:space:]]*#/ && NF { print $1 }' "$file"
}

ensure_backup_dir() {
    if (( BACKUP_CREATED == 0 )); then
        run mkdir -p "$BACKUP_DIR"
        BACKUP_CREATED=1
    fi
}

backup_target() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0
    ensure_backup_dir
    local dest="$BACKUP_DIR/${target#"$USER_HOME"/}"
    run mkdir -p "$(dirname -- "$dest")"
    run mv -- "$target" "$dest"
    warn "backup: $target -> $dest"
}

# Directory that a symlink ultimately points to (empty for broken links).
link_target() {
    local p="$1"
    [[ -L "$p" ]] || return 1
    readlink -f -- "$p"
}

# install_file <source> <target>
install_file() {
    local src="$1" target="$2"

    # Template files must be real files: paths inside them depend on $HOME.
    if grep -q '@HOME@' "$src" 2>/dev/null; then
        local tmp escaped
        tmp="$(mktemp)"
        escaped="${USER_HOME//\\/\\\\}"
        escaped="${escaped//&/\\&}"
        escaped="${escaped//|/\\|}"
        sed "s|@HOME@|$escaped|g" "$src" >"$tmp"

        if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$tmp" "$target"; then
            rm -f "$tmp"
            return 0
        fi
        backup_target "$target"
        run mkdir -p "$(dirname -- "$target")"
        if (( DRY_RUN )); then
            rm -f "$tmp"
            printf '   [dry-run] render %s -> %s\n' "$src" "$target"
        else
            mv -- "$tmp" "$target"
            chmod 644 "$target"
        fi
        return 0
    fi

    if [[ "$MODE" == "link" ]]; then
        # Already points to this exact file — nothing to do.
        if [[ -L "$target" && "$(link_target "$target" || true)" == "$(readlink -f -- "$src")" ]]; then
            return 0
        fi
        backup_target "$target"
        run mkdir -p "$(dirname -- "$target")"
        run ln -sfn -- "$src" "$target"
    else
        if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$src" "$target"; then
            return 0
        fi
        backup_target "$target"
        run mkdir -p "$(dirname -- "$target")"
        run cp -a --no-preserve=ownership -- "$src" "$target"
    fi
}

# Copy a fallback only when the target does not exist yet.
install_fallback() {
    local src="$1" target="$2"
    [[ -e "$target" || -L "$target" ]] && return 0
    run mkdir -p "$(dirname -- "$target")"
    run cp -a --no-preserve=ownership -- "$src" "$target"
    ok "fallback: $target"
}

# sync_tree <src-root> <target-root>
sync_tree() {
    local src_root="$1" target_root="$2" src rel
    while IFS= read -r -d '' src; do
        rel="${src#"$src_root"/}"
        case "$rel" in
            .gitkeep|*/.gitkeep|.DS_Store|*/.DS_Store) continue ;;
        esac
        install_file "$src" "$target_root/$rel"
    done < <(find "$src_root" -type f -print0)
}

# ---------------------------------------------------------------- options ---
while (( $# )); do
    case "$1" in
        -c|--copy)      MODE="copy" ;;
        --no-packages)  DO_PACKAGES=0 ;;
        --apps)         DO_APPS=1 ;;
        --no-oh-my-zsh) DO_OMZ=0 ;;
        --no-chsh)      DO_CHSH=0 ;;
        --no-theme)     DO_THEME=0 ;;
        --dry-run)      DRY_RUN=1 ;;
        --uninstall)    UNINSTALL=1 ;;
        -h|--help)      usage; exit 0 ;;
        *)              die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

(( EUID == 0 )) && die "Do not run this script as root. Run it as your user; it will ask for sudo when needed."

# --------------------------------------------------------------- uninstall --
if (( UNINSTALL )); then
    log "Removing symlinks that point into $DOTFILES"
    removed=0
    while IFS= read -r -d '' src; do
        rel="${src#"$CONFIG_SRC"/}"
        target="$USER_HOME/.config/$rel"
        if [[ -L "$target" ]] && [[ "$(link_target "$target" || true)" == "$(readlink -f -- "$src")" ]]; then
            run rm -f -- "$target"
            removed=$((removed + 1))
        fi
    done < <(find "$CONFIG_SRC" -type f -print0)

    while IFS= read -r -d '' src; do
        rel="${src#"$HOME_SRC"/}"
        target="$USER_HOME/$rel"
        if [[ -L "$target" ]] && [[ "$(link_target "$target" || true)" == "$(readlink -f -- "$src")" ]]; then
            run rm -f -- "$target"
            removed=$((removed + 1))
        fi
    done < <(find "$HOME_SRC" -type f -print0)

    ok "Removed $removed symlink(s). Generated files and backups were kept."
    exit 0
fi

# --------------------------------------------------------------- packages ---
install_pkg_list() {
    local file="$1" helper p
    local -a pkgs=() official=() aur=() missing=()
    mapfile -t pkgs < <(read_list "$file")
    (( ${#pkgs[@]} == 0 )) && return 0

    for p in "${pkgs[@]}"; do
        pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
    done

    if (( ${#missing[@]} == 0 )); then
        ok "all packages from $(basename "$file") are already installed"
        return 0
    fi

    for p in "${missing[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then
            official+=("$p")
        else
            aur+=("$p")
        fi
    done

    if (( ${#official[@]} )); then
        log "Installing official packages: ${official[*]}"
        run sudo pacman -S --needed --noconfirm "${official[@]}"
    fi

    if (( ${#aur[@]} )); then
        helper="$(command -v yay || command -v paru || true)"
        if [[ -n "$helper" ]]; then
            log "Installing AUR packages: ${aur[*]}"
            run "$helper" -S --needed --noconfirm "${aur[@]}"
        else
            warn "AUR helper (yay/paru) not found. Install these manually:"
            printf '     %s\n' "${aur[@]}"
        fi
    fi
}

install_packages() {
    command -v pacman >/dev/null 2>&1 || {
        warn "pacman not found — this installer targets Arch-based systems."
        warn "Skipping package installation; deploy the configs manually."
        return 0
    }

    log "Installing base packages"
    install_pkg_list "$DOTFILES/packages.txt"

    log "Installing AUR packages"
    install_pkg_list "$DOTFILES/packages-aur.txt"

    if (( DO_APPS )) && [[ -f "$DOTFILES/packages-apps.txt" ]]; then
        log "Installing optional desktop apps"
        install_pkg_list "$DOTFILES/packages-apps.txt"
    fi

    if command -v fc-cache >/dev/null 2>&1; then
        run fc-cache -f >/dev/null 2>&1 || true
    fi
}

# ------------------------------------------------------------- oh-my-zsh ---
install_oh_my_zsh() {
    local plugin src
    if [[ ! -d "$USER_HOME/.oh-my-zsh/.git" ]]; then
        log "Installing Oh My Zsh"
        if (( DRY_RUN )); then
            printf '   [dry-run] git clone ohmyzsh/ohmyzsh -> ~/.oh-my-zsh\n'
        else
            git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git \
                "$USER_HOME/.oh-my-zsh"
        fi
    else
        ok "Oh My Zsh is already installed"
    fi

    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        if [[ -d "$USER_HOME/.oh-my-zsh/custom/plugins/$plugin" ]]; then
            continue
        fi

        # Arch packages put plugins in /usr/share/zsh/plugins — reuse them
        # instead of downloading the same code again.
        src="/usr/share/zsh/plugins/$plugin"
        if [[ -d "$src" ]]; then
            run mkdir -p "$USER_HOME/.oh-my-zsh/custom/plugins"
            run ln -sfn "$src" "$USER_HOME/.oh-my-zsh/custom/plugins/$plugin"
            ok "linked plugin $plugin"
        else
            log "Installing zsh plugin: $plugin"
            run mkdir -p "$USER_HOME/.oh-my-zsh/custom/plugins"
            run git clone --depth=1 "https://github.com/zsh-users/$plugin.git" \
                "$USER_HOME/.oh-my-zsh/custom/plugins/$plugin"
        fi
    done
}

# ------------------------------------------------------------------ files ---
deploy_files() {
    log "Deploying configuration files ($MODE mode)"
    sync_tree "$CONFIG_SRC" "$USER_HOME/.config"
    sync_tree "$HOME_SRC"   "$USER_HOME"
    run chmod +x "$USER_HOME/.local/bin/screenshot" 2>/dev/null || true

    # Fallbacks make the desktop usable before matugen generates its palette.
    if [[ -d "$FALLBACK_SRC" ]]; then
        local src rel
        while IFS= read -r -d '' src; do
            rel="${src#"$FALLBACK_SRC"/}"
            install_fallback "$src" "$USER_HOME/.config/$rel"
        done < <(find "$FALLBACK_SRC" -type f -print0)
    fi
}

# -------------------------------------------------------------- wallpaper ---
setup_wallpaper() {
    local dir="$USER_HOME/Pictures/wallpaper"
    local state="$USER_HOME/.config/matugen/current-wallpaper"
    local default="$dir/11.jpg"

    run mkdir -p "$dir" "$USER_HOME/Pictures/Screenshots"

    if ! find "$dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -print -quit 2>/dev/null | grep -q .; then
        if [[ -f "$WALLPAPER_SRC/11.jpg" ]]; then
            run cp -a -- "$WALLPAPER_SRC/11.jpg" "$default"
            ok "Installed default wallpaper: $default"
        fi
    fi

    if [[ ! -f "$state" ]] || [[ ! -f "$(cat "$state" 2>/dev/null || true)" ]]; then
        run mkdir -p "$(dirname -- "$state")"
        if (( DRY_RUN )); then
            printf '   [dry-run] set wallpaper state -> %s\n' "$default"
        else
            printf '%s\n' "$default" >"$state"
        fi
    fi
}

apply_theme() {
    if [[ ! -x "$USER_HOME/.config/matugen/apply.sh" ]]; then
        warn "matugen apply.sh not executable — skipping theme generation"
        return 0
    fi
    if ! command -v matugen >/dev/null 2>&1 && [[ ! -x "$USER_HOME/.local/bin/matugen" ]]; then
        warn "matugen is not installed — using static fallback colors"
        return 0
    fi
    log "Generating theme from the wallpaper"
    if (( DRY_RUN )); then
        printf '   [dry-run] %s/.config/matugen/apply.sh\n' "$USER_HOME"
    else
        "$USER_HOME/.config/matugen/apply.sh" || warn "Theme generation failed; see ~/.cache/matugen/theme.log"
    fi
}

# ------------------------------------------------------------------ shell ---
setup_shell() {
    local zsh current
    zsh="$(command -v zsh || true)"
    [[ -n "$zsh" ]] || { warn "zsh not found — skipping login shell change"; return 0; }

    current="$(getent passwd "$USER" | cut -d: -f7 || true)"
    if [[ "$current" == "$zsh" ]]; then
        ok "Login shell is already zsh"
        return 0
    fi

    log "Changing login shell to $zsh"
    if (( DRY_RUN )); then
        printf '   [dry-run] chsh -s %s %s\n' "$zsh" "$USER"
    elif sudo -n true 2>/dev/null; then
        sudo chsh -s "$zsh" "$USER"
    else
        warn "Run this manually: chsh -s $zsh"
    fi
}

# ------------------------------------------------------------------- main ---
printf '\n%sDotfiles installer%s\n' "$C_BOLD" "$C_RESET"
printf 'repo: %s\n\n' "$DOTFILES"

if (( DO_PACKAGES )); then
    install_packages
fi

if (( DO_OMZ )); then
    install_oh_my_zsh
fi

deploy_files
setup_wallpaper

if (( DO_THEME )); then
    apply_theme
fi

if (( DO_CHSH )); then
    setup_shell
fi

printf '\n'
ok "Done. Log out and choose the Mango session, or restart your compositor."
if (( BACKUP_CREATED )); then
    printf '   Backups: %s\n' "$BACKUP_DIR"
fi
printf '   Reload zsh: exec zsh\n'
printf '\n'
