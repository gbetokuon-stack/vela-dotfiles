#!/usr/bin/env bash
# =============================================================================
#  Vela Dotfiles Sync — Pulls live ~/.config, ~/.local/bin/vela-*, and SDDM
#  theme into this repository cleanly (strips caches & private state).
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Syncing live Vela 2.0 configs into $REPO_DIR..."

mkdir -p "$REPO_DIR/config" "$REPO_DIR/bin" "$REPO_DIR/scripts" "$REPO_DIR/sddm" "$REPO_DIR/assets"

# 1. Config directories
CONFIG_DIRS=(
    hypr
    quickshell/vela
    matugen
    kitty
    fish
    rofi
    fastfetch
    btop
    cava
    qt6ct
    yazi
    vela/banner
)

for d in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$HOME/.config/$d" ]]; then
        rm -rf "$REPO_DIR/config/$d"
        mkdir -p "$REPO_DIR/config/$(dirname "$d")"
        cp -r "$HOME/.config/$d" "$REPO_DIR/config/$d"
    fi
done

# Single config files
[[ -f "$HOME/.config/starship.toml" ]] && cp "$HOME/.config/starship.toml" "$REPO_DIR/config/starship.toml"

# Clean private / machine-specific files
rm -rf "$REPO_DIR/config/hypr/dri" "$REPO_DIR/config/hypr/hyprland.lua.orig"
rm -f  "$REPO_DIR/config/fish/fish_variables"

# 2. Vela CLI & backend scripts
rm -f "$REPO_DIR/bin/"*
for f in "$HOME/.local/bin"/vela-*; do
    [[ -f "$f" ]] && cp "$f" "$REPO_DIR/bin/"
done

# 3. Hardware provisioner script
[[ -f "$HOME/setup-victus-drivers-and-rice.sh" ]] && cp "$HOME/setup-victus-drivers-and-rice.sh" "$REPO_DIR/scripts/"

# 4. SDDM login theme (excluding large cached wallpaper)
if [[ -d "$HOME/.local/share/sddm/themes/vela-nocturne" ]]; then
    rm -rf "$REPO_DIR/sddm/vela-nocturne"
    mkdir -p "$REPO_DIR/sddm/vela-nocturne"
    cp "$HOME/.local/share/sddm/themes/vela-nocturne/Main.qml" \
       "$HOME/.local/share/sddm/themes/vela-nocturne/metadata.desktop" \
       "$HOME/.local/share/sddm/themes/vela-nocturne/theme.conf" \
       "$REPO_DIR/sddm/vela-nocturne/" 2>/dev/null || true
fi

# Normalize hardcoded home paths so install.sh works for any username
python3 - "$REPO_DIR" "$HOME" <<'PY'
import os, sys
repo, home = sys.argv[1], sys.argv[2]
targets = [
    os.path.join(repo, "config/hypr/env.lua"),
    os.path.join(repo, "config/hypr/autostart.lua"),
    os.path.join(repo, "config/qt6ct/qt6ct.conf"),
]
for p in targets:
    if os.path.isfile(p):
        txt = open(p, encoding="utf-8").read()
        if home in txt:
            open(p, "w", encoding="utf-8").write(txt.replace(home, "__HOME__"))
PY

echo "✓ Sync complete! Review with: cd \"$REPO_DIR\" && git status"
