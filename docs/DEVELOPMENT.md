# NextraOS Development

## Primary Development Target

QEMU.

Every early milestone should be testable in a virtual machine.

---

# Build Requirements

The development environment should provide:

- Debian Trixie (or compatible, e.g. LMDE 7)
- `live-build` package
- `qemu-system-x86` package
- `ovmf` package (UEFI firmware for QEMU)
- `debootstrap` package
- Git
- Root access (build requires debootstrap/chroot)
- Network access during build (downloads packages)
- ~15 GB free disk space

Install on Debian Trixie:

    sudo apt install live-build qemu-system-x86 ovmf debootstrap

---

# Build

    ./build/build-iso

This runs `lb config` + `lb build` (requires sudo) and produces:

    dist/
        nextraos-live-amd64.iso

The ISO is an `iso-hybrid` image bootable on both BIOS and UEFI.

At present this command still builds the historical KDE prototype; it does not produce the Niri + Noctalia target. The separate Niri smoke profile corrects the live-user/greeter provisioning race; a fresh UEFI build reached tuigreet after Enter was sent through QMP, and `console=ttyS0` provided serial login and command access. Direct GLX and GTK GL are unavailable on this host, which has no `/dev/dri` or `/dev/kvm`; non-GL VirtIO/Bochs VGA paths show the greeter but cannot render Niri. A software-only QEMU render path works: host Mesa llvmpipe renders Weston 14's headless GL backend, QEMU SDL runs inside Weston over Wayland with `virtio-vga-gl`, and the guest uses TCG. The fresh ISO initialized guest `/dev/dri/renderD128` and `/dev/dri/card0`, reported `Virtual-1` at 1280×800, and exposed Noctalia wallpaper/bar/panel layers; `screenshot-screen` captured the launcher and a Foot window. A Ctrl+Alt+F2/F7 VT pause/resume preserved output without libseat EAGAIN. After a simulated Niri SIGKILL, greetd returned; Noctalia reached `failed/timeout` at its five-second stop timeout and no process remained, then relogin restarted Niri and Noctalia. This is headless software-rendering evidence, not native-GPU/performance qualification. Portal workflows, actual audio playback, shell-driven shutdown, persistence, and memory targets remain unverified. The host has no ALSA default PCM, so guest PipeWire's `Dummy Output` is not proof of audio playback.

### Headless Weston GL rendering smoke test

On hosts where QEMU's SDL GLX path is unavailable but surfaceless Mesa llvmpipe works, run QEMU inside Weston’s headless GL backend. This is an offscreen render test; it does not open a visible host window. It needs `weston`, Mesa EGL/llvmpipe and the built Niri smoke ISO:

```sh
runtime=$(mktemp -d "$PWD/dist/.niri-weston.XXXXXX")
printf 'Weston runtime: %s\n' "$runtime"
XDG_RUNTIME_DIR="$runtime" LIBGL_ALWAYS_SOFTWARE=1 weston \
  --backend=headless --renderer=gl --socket=niri-headless --no-config \
  --log="$runtime/weston.log" -- \
  env SDL_VIDEODRIVER=wayland LIBGL_ALWAYS_SOFTWARE=1 \
    NEXTRAOS_QEMU_DISPLAY=sdl NEXTRAOS_QEMU_GL=1 \
    ./tools/run-qemu dist/nextraos-niri-test-amd64.iso \
    -qmp "unix:$runtime/qmp.sock,server=on,wait=off" \
    -serial "unix:$runtime/serial.sock,server=on,wait=off" -monitor none
```

The smoke profile adds `console=ttyS0`; connect to `serial.sock` for boot output and a serial login. The live menu waits for a selection. After the Weston command prints the runtime directory, set `runtime` to that same path in a second shell; once `qmp.sock` appears, send Enter through QMP:

```sh
runtime=/path/printed/by/the/first/shell
python3 - "$runtime/qmp.sock" <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1])
f = s.makefile("rwb", buffering=0)
f.readline()
f.write(b'{"execute":"qmp_capabilities","id":"c"}\r\n')
while json.loads(f.readline()).get("id") != "c":
    pass
f.write(b'{"execute":"human-monitor-command","arguments":{"command-line":"sendkey ret"},"id":"k"}\r\n')
while json.loads(f.readline()).get("id") != "k":
    pass
s.close()
PY
```

Inside the guest, `niri msg action screenshot-screen` writes a desktop PNG under `~/Pictures/Screenshots/`. QMP `screendump` may return `no surface` for GL scanout; use the compositor's screenshot action for visual evidence. Remove the temporary runtime directory after Weston/QEMU have exited and any logs/screenshots are no longer needed.

First build takes 15-45 minutes depending on network speed.
Subsequent builds use the download cache and are faster.

The UEFI QEMU runners use a private temporary copy of the OVMF variable-store template and remove it on exit, rather than letting a VM modify the system package's shared template. All QEMU profiles expose an emulated HDA device through SDL audio; actual playback still depends on the host's audio backend. The default display is GL-enabled SDL with `virtio-vga-gl`; `NEXTRAOS_QEMU_GL=0` selects non-GL SDL or GTK. `NEXTRAOS_QEMU_DISPLAY=gtk` follows the GL toggle (use `NEXTRAOS_QEMU_DISPLAY=gtk NEXTRAOS_QEMU_GL=0` if GTK GL is unavailable). `NEXTRAOS_QEMU_DISPLAY=gtk-std` uses legacy Bochs VGA as a software-only diagnostic; it does not validate Niri rendering. `NEXTRAOS_QEMU_DISPLAY=none` disables the host window and uses non-GL VirtIO; it is for headless boot diagnostics, not Niri rendering (QEMU's `none` display rejects the GL device). Use QMP for keyboard input; QMP `screendump` does not work with GL scanout here, so use Niri's in-guest screenshot command for rendered frames.

---

# Niri package prototype

`./tools/build-niri-package` builds the pinned v26.04 source for Debian Trixie/AMD64 as an unprivileged user, using the Build-Depends from [`packages/nextraos-niri/debian/control`](../packages/nextraos-niri/debian/control). It verifies the commit, vendors Cargo dependencies from the locked manifest, and runs the package build offline; fetching and vendoring need network access.

The recipe has built successfully in a fresh Debian Trixie/AMD64 container, with all 195 upstream tests passing. Installing its `.deb` in a fresh Trixie container resolved dependencies and `niri --version` returned the pinned commit. The package is included only in the disposable Niri smoke profile, not the default KDE live-build; a successful desktop session and user-systemd unit check still require real runtime verification. See the [package notes](../packages/nextraos-niri/README.md).

## Noctalia v5 and session configuration prototype

The community-maintained Noctalia Trixie archive's signing key was checked against the recorded fingerprint. A disposable Trixie container accepted its signed index, installed pinned `noctalia` 5.2.1, and verified `noctalia --version` / `--help`, the package hash, and the TOML profile with `noctalia config validate`. Reproduce the isolated-container smoke procedure with `./tools/test-noctalia-package` (requires Docker and network access). The shell was not launched because the test has no Wayland session. See the provenance, dependency and key-rotation notes in [research](RESEARCH.md#noctalia-v5).

The Niri + Noctalia starter config is [`packages/nextraos-niri/nextraos-config.kdl`](../packages/nextraos-niri/nextraos-config.kdl). With the pinned Niri package installed, validate it using:

    niri validate --config packages/nextraos-niri/nextraos-config.kdl

It currently expects `noctalia`, `foot`, and WirePlumber's `wpctl` to be available. The companion [`noctalia-config.toml`](../packages/nextraos-niri/noctalia-config.toml) is checked by the isolated package test; it selects Secret Service, keeps the first-run wizard enabled, enables the shell polkit agent, and disables screen-time tracking, telemetry/external-IP lookups, and launcher exchange-rate lookups. The profile needs a real Secret Service provider (the Niri portal config selects GNOME Keyring) and a tested PAM unlock path. Neither config is installed by the Niri `.deb` or enabled by the default KDE live-build configuration.

The separate [`Niri smoke profile`](../build/profiles/niri-test/README.md) and [`build/build-niri-test-iso`](../build/build-niri-test-iso) stage these configs into a disposable project copy, preserve the root KDE package list, and scope the signed Noctalia APT source/key to the live-build chroot. The profile starts Noctalia through a user unit bound to `niri.service`, with a five-second stop timeout. On the freshly rebuilt ISO, Niri exposed `/dev/dri/renderD128`, `/dev/dri/card0`, and `Virtual-1` at 1280×800; Noctalia wallpaper/bar/panel layers, launcher IPC, and a Foot window were visible in an in-guest screenshot. Ctrl+Alt+F2/F7 VT resume kept output active without EAGAIN. Killing Niri returned greetd; Noctalia reached `failed/timeout` at the five-second bound with no process remaining, and relogin restarted Niri and Noctalia. This validates a software-rendered smoke session, not native-GPU performance or a production image. Portal workflows, actual playback, shell-driven shutdown/logout, persistence and memory acceptance remain open. The Noctalia repository remains community-maintained; mirroring/provenance review and plugin-update policy are still release gates.

---

# Clean

    ./auto/clean [stage]

Clean build cache. Use stage argument for targeted cleaning:

    ./auto/clean chroot    # After changing hooks or package lists (recommended)
    ./auto/clean binary    # After changing ISO config (boot params, etc.)
    ./auto/clean           # Full clean (rare, removes bootstrap cache)

Always clean before rebuild when hooks or packages change, otherwise
live-build may skip the modified steps due to caching.

---

# Run

## UEFI (default)

    ./tools/run-qemu

## BIOS (fallback)

    ./tools/run-qemu-bios

An optional first argument selects an ISO path; subsequent arguments are passed through to QEMU, for example `./tools/run-qemu ./dist/test.iso -m 8G`.

The VM provides:

- UEFI via OVMF
- 4 GB RAM
- 2 CPUs (host CPU model with KVM; `max` under TCG)
- KVM when `/dev/kvm` is accessible, otherwise slower multi-threaded TCG
- `virtio-vga-gl` with SDL GL for compositor rendering
- virtual network (user-mode, SSH forwarded to port 2222)
- USB tablet and keyboard

The current runner opens an SDL window with GL enabled for `virtio-vga-gl`; it does not expose a VNC server. Keep the GL path for Niri rendering tests. A VNC/non-GL profile would be a separate test and cannot substitute for accelerated session validation.

---

# Install Test

    ./tools/run-qemu-install

This requires OVMF/UEFI. It creates `dist/nextraos-test.qcow2` (32 GiB, sparse) on first run and preserves that disk for install/reboot persistence checks; it does not reset an existing test disk.

The test should verify:

- installer starts
- hardware detection works
- disk detection works
- networking works
- installation completes
- installed system boots

---

# Policy and collector smoke tests

    ./tools/test

The current test entrypoint checks each shell script's syntax, startup policy, pinned Niri packaging and Noctalia metadata/config-prototype assertions, QEMU GL/KVM/TCG and headless-display argument handling, BIOS-fallback arguments, no-clobber ISO publication against a dangling symlink, `systemctl --root` boot-link removal in an isolated temporary root (when available), and a one-sample CSV smoke test of the memory collector. `./tools/test-noctalia-package` is a separate Docker/network-dependent smoke test. The default test entrypoint does **not** build the Niri package or ISO, start Waydroid, launch a VM, boot a desktop, or validate persistence.

The next integration tests must cover package/session contents, Niri + Noctalia login, portals, audio, networking, installer startup, and install-to-virtual-disk reboot persistence.

---

# Idle-memory baseline

After booting an installed test image, run `./tools/measure-idle-memory --output results/<profile>-runN.csv` from the user session. The tool samples 5/30/60 minutes after boot and writes a metadata sidecar. Follow [MEMORY-BENCHMARK.md](MEMORY-BENCHMARK.md) for cold-boot count, display and 4/8/16 GiB profile requirements.

The collector does not establish that the <1024 MiB target has been met; retain and compare raw measurements.

---

# Development Rules

Keep changes small.

Prefer:

    one feature
    one design
    one test

over:

    giant implementation

---

# Debugging

All major services should provide useful logs.

Avoid silent failures.

When possible provide:

- journal logs
- installer logs
- compatibility logs
- VM logs

---

# Reproducibility

The build should avoid depending on:

- developer-specific paths
- developer-specific configuration
- undocumented host packages
- manually modified files

---

# CI

Eventually CI should:

1. build the ISO
2. validate its contents
3. boot it in QEMU
4. verify basic services
5. publish build artifacts

Advanced CI may test:

- installer
- Wayland
- networking
- application installation

Hardware-specific functionality should use dedicated runners.