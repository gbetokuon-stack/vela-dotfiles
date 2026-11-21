#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  HP Victus 15-fb3xxx (Ryzen 7 7445HS + Radeon 740M + RTX 4050 Mobile)
#  Full AMD + NVIDIA Open Driver Installer & "Vela" Hyprland Rice Provisioner
# ==============================================================================

BOLD="\e[1m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

step() { echo -e "\n${BOLD}${CYAN}==>${RESET} ${BOLD}$1${RESET}"; }
ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
warn() { echo -e "${YELLOW}  !${RESET} $1"; }

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Please run this script as your normal user (cuongacoustic), NOT root. It will invoke sudo when needed.${RESET}"
    exit 1
fi

step "Authenticating sudo session..."
sudo -v
# Keep sudo alive while script runs
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# ------------------------------------------------------------------------------
# 1. Enable [multilib] repository for 32-bit AMD & NVIDIA Vulkan/OpenGL libs
# ------------------------------------------------------------------------------
step "Enabling [multilib] in /etc/pacman.conf..."
if grep -qE '^\[multilib\]' /etc/pacman.conf; then
    ok "[multilib] is already enabled."
else
    sudo cp /etc/pacman.conf /etc/pacman.conf.bak.$(date +%Y%m%d%H%M%S)
    sudo python3 - <<'PY'
from pathlib import Path
p = Path("/etc/pacman.conf")
lines = p.read_text().splitlines()
out = []
i = 0
enabled = False
while i < len(lines):
    if lines[i].strip() == "#[multilib]" and i + 1 < len(lines) and "mirrorlist" in lines[i + 1]:
        out.append("[multilib]")
        out.append(lines[i + 1].lstrip("#"))
        i += 2
        enabled = True
    else:
        out.append(lines[i])
        i += 1
if not enabled:
    out.extend(["", "[multilib]", "Include = /etc/pacman.d/mirrorlist"])
p.write_text("\n".join(out) + "\n")
PY
    ok "Enabled [multilib] repository."
fi

# ------------------------------------------------------------------------------
# 2. Remove nouveau Vulkan ICD if present (replaced by nvidia-open + nvidia-utils)
# ------------------------------------------------------------------------------
if pacman -Q vulkan-nouveau &>/dev/null; then
    step "Removing vulkan-nouveau (switching RTX 4050 from nouveau to nvidia-open)..."
    sudo pacman -R --noconfirm vulkan-nouveau || warn "Could not remove vulkan-nouveau cleanly; continuing."
fi

# ------------------------------------------------------------------------------
# 3. Sync & Install Full AMD + NVIDIA + Laptop + Vela Rice Packages
# ------------------------------------------------------------------------------
step "Updating system and installing AMD, NVIDIA RTX 4050 (open), & Vela Rice packages..."

AMD_PKGS=(
    amd-ucode
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    vulkan-mesa-layers
    libva-utils
    vulkan-tools
    mesa-utils
)

NVIDIA_PKGS=(
    nvidia-open
    nvidia-utils
    lib32-nvidia-utils
    nvidia-prime
    nvidia-settings
    libva-nvidia-driver
    egl-wayland
    egl-gbm
    opencl-nvidia
)

SYSTEM_PKGS=(
    base-devel
    git
    power-profiles-daemon
    upower
    lm_sensors
    brightnessctl
    playerctl
    pamixer
    pavucontrol
    blueman
    jq
    bc
    imagemagick
    libnotify
)

RICE_PKGS=(
    quickshell
    matugen
    awww
    hyprlock
    hypridle
    hyprpicker
    hyprsunset
    hyprpolkitagent
    rofi
    fuzzel
    wl-clipboard
    cliphist
    satty
    grim
    slurp
    xdg-desktop-portal-gtk
    fish
    starship
    fastfetch
    btop
    cava
    eza
    bat
    yazi
    fzf
    adw-gtk-theme
    papirus-icon-theme
    nwg-look
    qt6ct
    qt5ct
    kvantum
    ttf-jetbrains-mono-nerd
    otf-geist-mono-nerd
    ttf-material-symbols-variable
    inter-font
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    otf-font-awesome
)

sudo pacman -Syu --needed --noconfirm "${AMD_PKGS[@]}" "${NVIDIA_PKGS[@]}" "${SYSTEM_PKGS[@]}" "${RICE_PKGS[@]}"
ok "All driver & rice packages installed."

# ------------------------------------------------------------------------------
# 4. Configure NVIDIA Open Kernel Modules + Hybrid Optimus RTD3 Power Saving
# ------------------------------------------------------------------------------
step "Configuring NVIDIA RTX 4050 (Ada Lovelace) modprobe & RTD3 D3cold power management..."

if pacman -Q xf86-video-nouveau &>/dev/null; then
    sudo pacman -R --noconfirm xf86-video-nouveau || true
fi

sudo depmod -a "$(uname -r)"

sudo tee /etc/modprobe.d/nvidia-victus.conf >/dev/null <<'EOF'
# HP Victus 15-fb3xxx: NVIDIA RTX 4050 Mobile (AD107M) Hybrid Optimus Config
blacklist nouveau
install nouveau /bin/false
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_DynamicPowerManagement=0x02 NVreg_EnableS0ixPowerManagement=1
EOF

sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null <<'EOF'
# Enable runtime PM (RTD3 D3cold) for NVIDIA RTX 4050 Mobile when idle
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto"
EOF

ok "Wrote /etc/modprobe.d/nvidia-victus.conf and /etc/udev/rules.d/80-nvidia-pm.rules."

# ------------------------------------------------------------------------------
# 5. Update UKI (/etc/kernel/cmdline) & mkinitcpio (Early KMS for AMD + NVIDIA)
# ------------------------------------------------------------------------------
if [[ -f /etc/kernel/cmdline ]]; then
    step "Updating /etc/kernel/cmdline for UKI NVIDIA DRM modeset & nouveau blacklist..."
    sudo cp /etc/kernel/cmdline /etc/kernel/cmdline.bak.$(date +%Y%m%d%H%M%S)
    sudo python3 - <<'PY'
from pathlib import Path
p = Path("/etc/kernel/cmdline")
tokens = p.read_text().strip().split()
for param in ["nvidia_drm.modeset=1", "nvidia_drm.fbdev=1", "module_blacklist=nouveau"]:
    if param not in tokens:
        tokens.append(param)
p.write_text(" ".join(tokens) + "\n")
PY
    ok "Updated /etc/kernel/cmdline."
fi

step "Updating /etc/mkinitcpio.conf for AMD + NVIDIA early KMS..."
sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak.$(date +%Y%m%d%H%M%S)
sudo python3 - <<'PY'
from pathlib import Path
import re

p = Path("/etc/mkinitcpio.conf")
text = p.read_text()
desired = "MODULES=(amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)"
new_text, count = re.subn(r'^MODULES=\([^)]*\)', desired, text, count=1, flags=re.M)
if count == 0:
    new_text = desired + "\n" + text
p.write_text(new_text)
PY
sudo mkinitcpio -P
ok "Initramfs rebuilt with AMD + NVIDIA modules."

# ------------------------------------------------------------------------------
# 6. Update GRUB Kernel Parameters
# ------------------------------------------------------------------------------
if [[ -f /etc/default/grub ]]; then
    step "Updating GRUB kernel parameters for NVIDIA DRM modeset & fbdev..."
    sudo cp /etc/default/grub /etc/default/grub.bak.$(date +%Y%m%d%H%M%S)
    sudo python3 - <<'PY'
from pathlib import Path
import re

p = Path("/etc/default/grub")
text = p.read_text()
m = re.search(r'^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"$', text, flags=re.M)
if m:
    params = m.group(1).split()
    for needed in ["nvidia_drm.modeset=1", "nvidia_drm.fbdev=1"]:
        if needed not in params:
            params.append(needed)
    new_line = f'GRUB_CMDLINE_LINUX_DEFAULT="{" ".join(params)}"'
    text = text[:m.start()] + new_line + text[m.end():]
    p.write_text(text)
PY
    if [[ -d /boot/grub ]]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        ok "GRUB configuration regenerated."
    else
        warn "/boot/grub not found; skipping grub-mkconfig."
    fi
fi

# ------------------------------------------------------------------------------
# 7. Enable Hardware & Power Services
# ------------------------------------------------------------------------------
step "Enabling NVIDIA power, Power Profiles, Bluetooth, and Wi-Fi (iwd) services..."
sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now iwd.service || warn "iwd enable returned non-zero (safe to ignore if using another wifi daemon)."
ok "System services enabled."

# ------------------------------------------------------------------------------
# 8. Refresh Font Cache & Apply Vela GTK / Matugen / Hyprland Theme
# ------------------------------------------------------------------------------
step "Refreshing font cache & applying Vela Material You theme..."
fc-cache -f

# Apply GTK dark theme settings
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name 'Inter 10' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true

# Apply initial wallpaper & generate Matugen v4 dynamic colors
if [[ -x "$HOME/.local/bin/vela-theme" ]]; then
    FIRST_WALL=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort | head -n1 || true)
    if [[ -n "$FIRST_WALL" ]]; then
        "$HOME/.local/bin/vela-theme" "$FIRST_WALL" --no-reload || warn "vela-theme had a warning (will retry after session reload)."
    fi
fi

# Refresh Hyprland & launch Vela desktop shell if currently inside Hyprland
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    step "Starting Vela desktop shell inside live Hyprland session..."
    pkill -x dunst 2>/dev/null || true
    pgrep -x awww-daemon >/dev/null || (nohup awww-daemon >/dev/null 2>&1 &)
    sleep 0.5
    hyprctl reload || true
    pkill -f "quickshell -c vela" 2>/dev/null || true
    nohup quickshell -c vela >/tmp/vela-quickshell.log 2>&1 &
    sleep 1
    if [[ -n "${FIRST_WALL:-}" ]]; then
        awww img "$FIRST_WALL" --transition-type grow --transition-pos 0.5,0.5 --transition-fps 144 --transition-duration 0.9 2>/dev/null || true
    fi
    ok "Vela shell launched! Check /tmp/vela-quickshell.log if anything looks off."
fi

echo -e "\n${BOLD}${GREEN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}  DONE! All AMD + NVIDIA RTX 4050 drivers & Vela Rice are installed!${RESET}"
echo -e "${BOLD}${YELLOW}  IMPORTANT: Reboot once so the new nvidia-open kernel module loads${RESET}"
echo -e "${BOLD}${YELLOW}  and replaces nouveau cleanly (run: reboot).${RESET}"
echo -e "${BOLD}${CYAN}  After reboot, test GPU offload with: nvidia-smi && prime-run glxinfo | grep renderer${RESET}"
echo -e "${BOLD}${GREEN}========================================================================${RESET}"
