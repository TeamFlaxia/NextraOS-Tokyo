# Niri desktop smoke profile

This profile builds an isolated, desktop-only live ISO for the first Niri +
Noctalia QEMU session test. It does not replace the historical KDE package
list in the project tree.

The profile deliberately includes only the desktop/session layer needed for
that proof: the pinned Niri package, pinned Noctalia v5, greetd + tuigreet,
`user-setup` for the live account, Nautilus, PipeWire/WirePlumber,
NetworkManager, GNOME/GTK portals, GNOME Keyring with its PAM module, and the
small Noctalia recommendations explicitly listed in `desktop.list.chroot`.
A staged chroot hook creates the separate unprivileged `greeter` account that
runs tuigreet; Debian's greetd package creates `_greetd` for its daemon, not the
greeter UI account. The greetd session menu launches the installed
`niri-session` desktop entry. Niri and Noctalia prototypes are seeded from
`/etc/skel` for the live user. The profile installs a user `noctalia.service`
bound to `niri.service` with `TimeoutStopSec=5s`; the Niri config starts that
unit so a compositor exit cannot leave a Noctalia process indefinitely attached
to a stale Wayland socket. The fresh-ISO crash test showed `Result=timeout` and
no process remaining after the stop bound, then a clean unit start after relogin.
The staged boot line sets live-config's `noautologin` option so the default
console auto-login cannot race greetd, and enables `console=ttyS0` for headless
QEMU diagnostics; greetd uses VT 7 to match Debian's packaged service unit.

No KDE, application starter kit, Waydroid, VM integration, Calamares installer,
Flatpak setup, or old production-hardening hook is included. The latter
currently opens SSH/VNC firewall ports and installs unrelated diagnostics; it
must be redesigned separately before reuse. This is a session smoke image,
not a production release or persistent-install test.

Noctalia is sourced from its community APT archive only in the live-build
chroot. The archive list, exact version pin, package-origin pin and signing key
use `.chroot` live-build suffixes, with `Signed-By` scoped to the pinned key.
They are not added as `.binary` sources or keys to the resulting live system.
The build seeds Debian CA roots during debootstrap so the first HTTPS APT update
can validate the archive certificate; `ca-certificates` remains in the image.
The build script verifies the key fingerprint and refuses to overwrite an
existing ISO. It requires a previously built
`dist/packages/nextraos-niri_26.04-1_amd64.deb`.

Build and boot manually (the test image is UEFI-only and needs OVMF):

```sh
./build/build-niri-test-iso
./tools/run-qemu dist/nextraos-niri-test-amd64.iso
```

The UEFI live menu waits for Enter. For headless Weston runs, send QMP `sendkey ret` after the QMP socket appears; the [development guide](../../../docs/DEVELOPMENT.md) includes a helper. The smoke profile's `console=ttyS0` provides a serial login/command channel.

If SDL/GLX is unavailable but a visible boot/login window is useful, use
`NEXTRAOS_QEMU_DISPLAY=gtk NEXTRAOS_QEMU_GL=0`; `NEXTRAOS_QEMU_DISPLAY=gtk-std`
selects legacy VGA for diagnostics. These non-GL modes do not validate Niri.
For headless rendering with software Mesa, use the Weston/llvmpipe procedure in
[`docs/DEVELOPMENT.md`](../../../docs/DEVELOPMENT.md): QEMU SDL runs inside
Weston's headless GL backend and presents `virtio-vga-gl` to the guest. This
validates rendering without physical GPU/KVM, but has no visible host window and
is not a performance test. Use the guest's
`niri msg action screenshot-screen` for rendered frames; QMP `screendump` may
return `no surface` on GL scanout. `NEXTRAOS_QEMU_DISPLAY=none` remains a
non-GL boot diagnostic only.

Fresh-ISO QEMU evidence includes an active Niri output, Noctalia layer-shell
surfaces and launcher, a mapped Foot window, VT pause/resume, and recovery to
greetd plus relogin after a compositor SIGKILL. The Noctalia process was gone
at the five-second stop bound (unit result `timeout`) and restarted successfully
with the next Niri session. The test ISO is still not accepted: portal workflows,
actual audio playback, shell-driven shutdown, logout, installation persistence
and 4/8/16 GiB memory profiles remain gates.
