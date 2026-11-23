# Vela 2.0 Troubleshooting

Quick fixes for the most common breakages. Always back up `~/.config` before
big changes; `install.sh` already does this automatically.

## Hyprland won't start / black screen

1. Log in through a fallback session (GNOME/Xfce) or a TTY.
2. Check the config parses: `hyprctl -q reload` and read the error.
3. Restore the latest backup from `~/.config-backup-vela-*`.
4. Common cause: a deprecated `.conf` file. Hyprland 0.57+ **only** loads
   `~/.config/hypr/hyprland.lua` (Lua API). See `config/hypr/hyprland.lua`.

## Screen shader looks wrong (vignette/grain)

The shader is `~/.config/hypr/shaders/vela-vignette.frag`, referenced from
`config/hypr/look.lua` as `decoration.screen_shader`. Disable it instantly with:

```sh
hyprctl keyword decoration:screen_shader ""
```

There is exactly one shader slot; setting a new one replaces the previous.

## Glow / wobble / motion blur missing after a tuning change

`vela-ctl` applies partial `hl.config` tables (they merge, not replace). Check
with `hyprctl getoption decoration:glow:enabled`. Toggle them from
**Super+I → Kính mờ** or:

```sh
~/.local/bin/vela-ctl set glow_enabled false
~/.local/bin/vela-ctl set wobble_enabled false
~/.local/bin/vela-ctl set motion_blur_enabled true
```

Games and fullscreen windows opt out of wobble via `config/hypr/rules.lua`.

## Quickshell shell gone / panels missing

```sh
pgrep -a quickshell
qs -c vela ipc show
journalctl --user -b | grep -i quickshell
```

Restart with `quickshell -c vela &`. Root-relative imports (`import "root:/..."`)
are deprecated since Quickshell 0.2; this config does not use them.

LSP for QML editing: an empty `.qmlls.ini` lives in `config/quickshell/vela/`;
Quickshell populates it on first run. It is gitignored because it is local.

## NVIDIA dGPU not sleeping (battery drain)

```sh
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
hyprctl getoption misc:vrr
```

`vela-telemetry` deliberately avoids waking NVIDIA when RTD3 is active. Keep
`motion_blur` off on battery. Re-run `scripts/setup-victus-drivers-and-rice.sh`
after a kernel update to rebuild initramfs with early KMS.

## Config changes don't survive `sync.sh`

`sync.sh` copies live `~/.config` into the repo and normalizes `$HOME` to
`__HOME__`. That is expected: `autostart.lua`, `env.lua` and `qt6ct.conf` will
always show a one-line diff against the live files. Private files
(`fish_variables`, `hypr/dri/`, `*.orig`) are intentionally skipped.

## Firefox / Zen chrome not following the wallpaper

`vela-theme` writes `~/.config/vela/firefox-userChrome.css` from Matugen and
copies it into every detected Firefox/Zen profile's `chrome/userChrome.css`.
Firefox only honours it when
`about:config → toolkit.legacyUserProfileCustomizations.stylesheets = true`.
Restart Firefox after the first install.

## Native Wi-Fi status in the bar

Quickshell's 0.3 networking module requires NetworkManager (`NetworkManager.service`
+ its D-Bus interface). This machine currently uses `iwd`/another backend and
NetworkManager is inactive, so network status still comes from `vela-telemetry`.
The native module was therefore intentionally left off rather than showing a
fake "offline" state.

## Sync / update

```sh
./sync.sh          # live -> repo
./update.sh        # repo -> live (fetch, install, reload)
```
