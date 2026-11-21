#!/usr/bin/env bash
# =============================================================================
#  Vela 2.0 "Nocturne Prism" — Automated Dotfiles Installer for Arch Linux
#  Hyprland (Lua API) + Quickshell + Matugen v4 + PipeWire + 144Hz Springs
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-vela-$(date +%Y%m%d-%H%M%S)"
INSTALL_PKGS=0

for arg in "$@"; do
    case "$arg" in
        --with-packages) INSTALL_PKGS=1 ;;
        -h|--help)
            echo "Usage: ./install.sh [--with-packages]"
            echo "  --with-packages   Install Arch Linux rice dependencies via pacman before linking"
            exit 0
            ;;
    esac
done

BOLD="\e[1m"; CYAN="\e[36m"; GREEN="\e[32m"; YELLOW="\e[33m"; RESET="\e[0m"
step() { echo -e "\n${BOLD}${CYAN}==>${RESET} ${BOLD}$1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }

if [[ "$INSTALL_PKGS" -eq 1 ]]; then
    step "Installing Vela 2.0 dependencies via pacman..."
    PKGS=(
        hyprland quickshell matugen awww hyprlock hypridle hyprpicker hyprsunset hyprpolkitagent
        kitty fish starship fastfetch btop cava eza bat yazi fzf rofi
        wl-clipboard cliphist grim slurp satty libnotify brightnessctl playerctl pavucontrol
        power-profiles-daemon upower lm_sensors jq bc imagemagick
        adw-gtk-theme papirus-icon-theme qt6ct kvantum nwg-look xdg-desktop-portal-gtk
        ttf-jetbrains-mono-nerd inter-font noto-fonts noto-fonts-emoji otf-font-awesome
    )
    sudo pacman -Syu --needed --noconfirm "${PKGS[@]}"
    ok "Packages installed."
fi

step "Backing up existing configs to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR" "$HOME/.config" "$HOME/.local/bin" "$HOME/Pictures/Wallpapers" "$HOME/.cache/vela"

for item in hypr quickshell/vela matugen kitty fish rofi fastfetch btop cava qt6ct yazi vela/banner starship.toml; do
    if [[ -e "$HOME/.config/$item" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$item")"
        cp -a "$HOME/.config/$item" "$BACKUP_DIR/$item"
    fi
done
ok "Backup saved."

step "Deploying Vela 2.0 configuration files..."
cp -r "$REPO_DIR/config/." "$HOME/.config/"
mkdir -p "$HOME/.config/fish/conf.d" "$HOME/.config/qt6ct/colors" "$HOME/.config/yazi"

# Expand __HOME__ placeholders to current user's $HOME
python3 - "$HOME" <<'PY'
import os, sys
home = sys.argv[1]
for rel in (
    ".config/hypr/env.lua",
    ".config/hypr/autostart.lua",
    ".config/qt6ct/qt6ct.conf",
):
    p = os.path.join(home, rel)
    if os.path.isfile(p):
        txt = open(p, encoding="utf-8").read()
        if "__HOME__" in txt:
            open(p, "w", encoding="utf-8").write(txt.replace("__HOME__", home))
PY
ok "Configs deployed to ~/.config."

step "Installing Vela CLI helpers into ~/.local/bin..."
cp -f "$REPO_DIR/bin/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin"/vela-*
ok "CLI helpers installed."

if [[ -d "$REPO_DIR/sddm/vela-nocturne" ]]; then
    step "Installing local Vela Nocturne SDDM theme copy..."
    mkdir -p "$HOME/.local/share/sddm/themes/vela-nocturne"
    cp -r "$REPO_DIR/sddm/vela-nocturne/." "$HOME/.local/share/sddm/themes/vela-nocturne/"
    ok "SDDM theme staged (run 'vela-login-install' to apply system-wide)."
fi

step "Applying GTK theme defaults & Material You palette..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name 'Inter 10' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true

if [[ -x "$HOME/.local/bin/vela-theme" ]] && [[ -n "$(ls -A "$HOME/Pictures/Wallpapers" 2>/dev/null || true)" ]]; then
    "$HOME/.local/bin/vela-theme" --restore || true
fi

echo -e "\n${BOLD}${GREEN}✓ Vela 2.0 installed successfully!${RESET}"
echo -e "  ${YELLOW}Tip:${RESET} Put wallpapers in ~/Pictures/Wallpapers, then press ${BOLD}Super + W${RESET} to switch themes or ${BOLD}Super + /${RESET} for keybinds."
