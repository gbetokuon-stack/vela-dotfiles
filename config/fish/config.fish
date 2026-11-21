# Vela Fish Shell Configuration
set -g fish_greeting ""

# Ensure ~/.local/bin is first on PATH
fish_add_path -p ~/.local/bin

# Modern CLI replacements
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --level=2 --icons"
alias cat="bat --style=plain --paging=never"
alias ff="fastfetch"
alias acoustic="~/.local/bin/vela-banner"
alias hyprland="/usr/bin/start-hyprland"
alias login-theme="~/.local/bin/vela-login-install"

# HP Victus Dual-GPU Shortcuts (RTX 4050 offload & status)
alias nrun="prime-run"
alias gpu-status="cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status && lspci -k -s 01:00.0 | grep 'Kernel driver'"
alias vela-wall="~/.local/bin/vela-theme"

# Interactive startup: Starship prompt + 3D Slanted Blurred "Acoustic" Banner
if status is-interactive
    if command -q starship
        starship init fish | source
    end
    if test -x ~/.local/bin/vela-banner
        ~/.local/bin/vela-banner
    end
end
