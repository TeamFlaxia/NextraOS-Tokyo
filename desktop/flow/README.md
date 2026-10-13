# Flow desktop profile

This is the desktop configuration exercised on a physical Debian 13/AMD64
host with Niri v26.04 and a locally patched native Noctalia v5.2.1. It is an
opt-in profile, separate from the existing Niri smoke-image prototype. It
does not change the default live-build profile or claim new ISO validation.

## Desktop behavior

- One 48px bottom taskbar: persistent app search and running apps on the left;
  IME tray, notifications, network, volume, settings and clock on the right.
- No separate top bar, start button or dock.
- Niri scrolling tiles with 14px gaps and rounded corners; floating windows
  remain available with `Super+V`.
- WezTerm as the terminal, with integrated minimize/maximize/close controls on
  the right. GTK uses the same button order; Qt uses Fusion and Breeze icons.
- Japanese keyboard and Fcitx5/Mozc input; Inter and Noto fonts.
- Flow light/dark palette and an original procedural wallpaper, without
  bundled Apple artwork, icons or proprietary themes.
- Session environment synchronization for D-Bus/systemd portal activation.

Important shortcuts: `Super+T` terminal, `Super+E` files, `Super+Space` launcher,
`Alt+Tab` switcher, `Super+I` settings, `Super+F` maximize column,
`Super+Shift+F` fullscreen, and `Print` screenshot selection.

## Prerequisites

Use the exact source pins in `sources.json`. The repository's existing Niri
package recipe already targets the same v26.04 source revision. Install
WezTerm separately (the tested release is `20240203-110809-5046fc22`), Niri,
Fcitx5/Mozc, lxpolkit, Nautilus, qt6ct, Breeze icons/cursors, Inter/Noto/Noto CJK
fonts, playerctl and brightnessctl as needed. The terminal wrapper supports
either `/usr/bin/wezterm` or an official Debian package extracted into
`~/.local/opt/wezterm`.

For session integration, provide `dbus-user-session`, PipeWire/WirePlumber,
`xdg-desktop-portal`, its GTK and GNOME backends, and a Secret Service provider
such as GNOME Keyring. Secret Service/PAM unlock and screen sharing still need
independent validation on a new installation. Packages and runtimes are not
installed by the profile installer.

The bar input is **not supported by unmodified Noctalia v5.2.1**. Build the
patched shell first, following the pinned upstream `BUILDING.md` for build
dependencies:

```sh
git clone https://github.com/noctalia-dev/noctalia.git /path/to/noctalia
git -C /path/to/noctalia checkout 6ef43e2bf2f3d5b4205ec72a72e34a2ab76ce3b4
./tools/patch-flow-noctalia /path/to/noctalia
meson setup /path/to/noctalia/build-flow /path/to/noctalia \
  --prefix "$HOME/.local/opt/noctalia-flow" --buildtype=release -Dtests=disabled
meson compile -C /path/to/noctalia/build-flow
meson install -C /path/to/noctalia/build-flow
```

The wrapper expects the binary at `~/.local/opt/noctalia-flow/bin/noctalia` and
assets at `~/.local/opt/noctalia-flow/share/noctalia/assets`. Set
`NOCTALIA_FLOW_PREFIX` to use another matching installation prefix. The
shell's bundled fonts/assets must be installed along with the binary.

The patch adds compact bar text input, keyboard/IME event routing, Niri
focused-window fallback, terminal title formatting, compact switcher spacing,
and Japanese translations. `noctalia/LICENSE.upstream` retains the upstream
MIT notice. No upstream shell binaries or third-party font/icon files are
redistributed here. The local plugin is declared MIT; `flow.png` is the
original wallpaper produced for this profile.

## Install and restore

Review the paths before installing into the current user's home:

```sh
./tools/install-flow-profile --dry-run
./tools/install-flow-profile
```

The installer substitutes `@HOME@` only in the exported text files, backs up
all replaced files under `~/.local/state/nextraos-flow/backups/<timestamp>`,
and copies the profile. It does not run package commands, start/stop services,
change the running desktop or modify dconf. Existing file symlinks are backed
up and replaced with regular files; directory symlinks outside the selected
home are rejected. Restore the saved files to revert a previous configuration;
remove newly installed files that had no previous counterpart.

Ensure `~/.local/bin` is on `PATH`, use `niri-session` for the next login, and
let Niri start `noctalia-flow`, Fcitx5 and lxpolkit. The CLI wrapper does not
re-import the session environment on every IPC call. `desktop-session-sync`
imports only display/desktop/socket variables and restarts portals only when
the environment changed or a backend is inactive. The custom user target
supports existing manually started Niri sessions; it is not a replacement for
a greeter/PAM configuration.

Run `flow-theme-sync` once after installation to apply the GTK/dconf button
layout and theme. Noctalia then invokes it on theme-mode changes. Machine
specific lock-screen output coordinates and the host's extracted Qt plugin
path were intentionally omitted; use upstream output-aware lock-screen
placement and system Qt plugin discovery.

The optional Discord snippet is at `optional/discord-flags.conf`; copy it to
`~/.var/app/com.discordapp.Discord/config/discord-flags.conf` only when using
that Flatpak. It selects Wayland without modifying sandbox permissions,
accounts, tokens, browser profiles or application data.

## Scope and evidence

This import contains desktop preferences and shell source changes only. It
contains no QEMU/libvirt/Windows/macOS VM definitions, VM disks, ISO images,
VM launchers, WinApps configuration, credentials, notification/usage history,
browser profiles or runtime caches. The small Niri rule for existing Android
surfaces is a tiling preference; Waydroid images, vendor repairs, initialization
and its launcher are not included in this profile.

On the original host, the bottom search input (including IME), launcher,
window titles and compact switcher were exercised with the patched binary.
After repairing portal activation, a Files launch from the Noctalia launcher
mapped in approximately 0.44 seconds in one warm measurement; Flatpak Discord
reached its main UI. This is a host observation, not a benchmark or an ISO
performance claim. Voice, screen sharing, complete session/PAM behavior and
memory targets remain unverified.

For this import, run `./tools/test`, validate the rendered KDL with `niri
validate --config <path>`, and lint the plugin with the patched `noctalia
plugins lint <directory>`. The source patch is checked against the exact
upstream revision. A fresh build/boot of the ISO is outside this import.
