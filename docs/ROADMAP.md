# NextraOS Tokyo Roadmap

This roadmap follows [`addinfo.md`](../addinfo.md). The current KDE-based live-build image is a historical prototype, not the target desktop. “Implemented” is not the same as “verified”: the reversible Niri smoke profile now has QEMU evidence for rendering and recovery, while unresolved desktop, memory and persistence gates remain tracked below.

## Phase 0 — Reproducible baseline

**Status: In progress**

- Pin Debian Trixie package inputs and document external package trust.
- Build a minimal Debian/AMD64 baseline with a reproducible build procedure.
- Establish a QEMU baseline and collect boot and idle-memory measurements.
- Verify which services start by default.

Current work: the repository has a static test entrypoint and an idle-memory collector; neither substitutes for the baseline's repeated boot/service/memory measurements. Niri has no compositor package in Debian Trixie, but the pinned project package has built in a Trixie/AMD64 container and passed all 195 upstream tests. Noctalia v5 has an external Trixie APT archive; its third-party trust and versioning are pinned for the disposable test profile, not treated as Debian security support.

## Phase 1 — Niri + Noctalia Wayland desktop

**Status: Fresh Niri smoke ISO boots UEFI and renders Niri + Noctalia under headless Weston/llvmpipe; VT resume and compositor-failure relogin verified; Stage 1 remains partial**

- Build and package Niri from a pinned upstream release for Debian Trixie/AMD64.
- Install a pinned Noctalia v5 build and its reviewed dependencies.
- Provide a safe login/session start, terminal, app launcher, file manager, networking controls, portals, audio, shutdown and recovery behavior.
- Boot and test the session in QEMU before removing the KDE prototype fallback.

Acceptance: clean login to Niri + Noctalia, functional network/audio/portals, and safe behavior after logout or compositor failure.

Current evidence by gate (the phase remains unaccepted):

| Gate | Evidence observed | State |
| --- | --- | --- |
| UEFI boot and login | Freshly rebuilt smoke ISO booted through the live menu (Enter sent via QMP for headless boot), reached tuigreet, and accepted serial `user`/`live` login | Verified in fresh ISO |
| Niri renderer/output | Fresh ISO: Niri v26.04 used guest `/dev/dri/renderD128`, initialized `/dev/dri/card0`, and exposed `Virtual-1` at 1280×800 | Verified in fresh ISO/QEMU |
| VT pause/resume | Ctrl+Alt+F2 then Ctrl+Alt+F7 returned to the session; output and Noctalia layers stayed active, and the Niri journal contained no libseat EAGAIN | Verified once in fresh ISO |
| Visible graphics / Noctalia shell | Fresh ISO layer IPC listed Noctalia wallpaper, top bar, click shield and panel; `screenshot-screen` captured the rendered desktop | Verified; [fresh-ISO screenshot](assets/niri-weston-launcher.png) |
| Launcher and app launch | Fresh ISO: Noctalia launcher opened via IPC; Niri reported the `foot` surface and the screenshot shows both | Verified in fresh smoke ISO |
| Portals | D-Bus `Peer.Ping` activated a portal service | Partial: file chooser/screencast workflows not tested |
| Audio | PipeWire enumerated `Dummy Output`; host QEMU SDL/ALSA had no default PCM | Partial: playback not verified |
| Networking | `ping -c 1 -W 5 1.1.1.1` succeeded with 0% packet loss | Verified for basic guest traffic |
| Compositor-failure recovery | Killing `niri.service` returned greetd to its greeter; `noctalia.service` reached `failed/timeout` after the 5-second stop timeout with no process left; relogin restarted Niri and Noctalia | Verified once in fresh ISO |
| Shutdown | A prior guest console `poweroff` shut QEMU down; user-facing shell shutdown remains untested | Partial |

The default `tools/run-qemu` mode requests `virtio-vga-gl` and SDL GL. Direct GLX/GTK GL are unavailable on this host, which has no `/dev/dri` or `/dev/kvm`; earlier non-GL VirtIO/Bochs runs correctly failed Niri's renderer requirement. A working software-only render path was found: Mesa surfaceless llvmpipe drives Weston 14's headless GL backend, and QEMU SDL runs inside Weston with `SDL_VIDEODRIVER=wayland`, `LIBGL_ALWAYS_SOFTWARE=1`, and `virtio-vga-gl` under TCG. The fresh smoke ISO pauses at its live boot menu, so headless runs must send Enter through QMP; its `console=ttyS0` option then provides a serial login and guest command channel. In that guest, Niri v26.04 initialized `/dev/dri/renderD128` and `/dev/dri/card0`, brought up `Virtual-1` at 1280×800, and produced Noctalia layer-shell surfaces. Niri's in-guest `screenshot-screen` action captured the launcher, wallpaper, top bar and a Foot window; QEMU's QMP `screendump` still reports `no surface` for the GL output. This headless workaround proves rendering without a physical GPU, but does not qualify native-GPU performance. The earlier libseat EAGAIN was not reproduced during the GL/virgl VT pause/resume run; the non-GL-path error's root cause remains unproven.

The Niri v26.04 package recipe is under `packages/nextraos-niri/`; a fresh Trixie/AMD64 container build passed all 195 upstream tests. A second Trixie container installed the `.deb`, resolved declared runtime dependencies, and reported the pinned commit with `niri --version`. Noctalia v5's repository key, pinned package hash, dependency install, CLI, and current project TOML config validation were verified in separate Trixie containers; `nextraos-config.kdl` also passes the pinned Niri parser. The reversible `build/build-niri-test-iso` profile uses a chroot-only signed Noctalia source and replaces the desktop list only in its disposable staging copy. Its Niri config starts a user `noctalia.service` bound to `niri.service` with a bounded stop timeout: on the fresh ISO, a compositor SIGKILL returned greetd, the unit reached `failed/timeout` at five seconds with no lingering process, and relogin started Niri and Noctalia successfully. Portal workflows, actual audio playback, shell-driven shutdown, persistence, and 4/8/16 GiB memory acceptance remain open. The host's QEMU SDL audio backend has no ALSA default device and the guest reports `Dummy Output`, so do not infer playback from PipeWire startup. The root KDE desktop package list remains selected; shared Waydroid/libvirt lifecycle hooks have separate on-demand changes.

## Phase 2 — Memory and startup optimization

**Status: Not measured**

- Use identical 1920×1080 single-display, no-user-app conditions.
- Test 4, 8 and 16 GiB profiles across multiple cold boots.
- Record `MemTotal - MemAvailable`, PSS, swap, zram, PSI and boot timing at 5/30/60 minutes.
- Meet idle host memory below 1024 MiB; 850 MiB remains a development goal.

Acceptance: publish raw samples and median/range per profile. No cache dropping, misleading swap accounting, security reductions, or usability regression.

## Phase 3 — Android

**Status: Integration scaffold exists; runtime test pending**

- Integrate Waydroid and binder only when requested.
- Download images only on user-selected install or first launch, with clear progress and errors.
- Verify APK install, app discovery, Wayland windows, clipboard/filesystem boundaries and persistent app data.

Debian's Waydroid package enables `waydroid-container.service` for `multi-user.target` by default. The live-build hook and Calamares post-install module disable that boot link via `systemctl --root=... disable` while preserving D-Bus/systemd activation; the container's drop-in then requires initialization and binderfs on explicit start. Static/systemd-root policy tests pass; actual first-start/stop/restart and persistence remain unverified.

## Phase 4 — Virtualization

**Status: Integration scaffold exists; runtime test pending**

- Provide QEMU/KVM through libvirt with local socket activation.
- Do not start guest VMs automatically on login.
- Verify VM creation, start, shutdown, suspend, storage persistence and SPICE access.
- Keep host filesystem/device shares opt-in and networking isolated by default.

The Debian Trixie package `libvirt-daemon` includes `libvirtd.socket`; current configuration enables that socket for selected VM support rather than eagerly enabling the daemon. Validate activation and access controls in the built system.

## Phase 5 — Performance tuning

**Status: Not started**

Tune kernel modules, initramfs, zram, services, GPU, QEMU CPU/I/O only after collecting a baseline. Accept a change only when repeatable measurements improve without security, stability or interaction regressions.

## Phase 6 — Distribution and installer

**Status: Existing installer prototype; Tokyo requirements not validated**

- Keep installation network-first and compute disk requirements from selected components and guest images.
- Verify hardware/network detection, locale/timezone, account creation, component selection, download failure handling and installation completion.
- Test persistent files, settings, package updates, Waydroid data and VM disks across reboot.
- Produce a reproducible ISO, QEMU boot test and install-to-virtual-disk regression.

The current Calamares module has `packages.conf` operations empty and some ecosystems are already in the ISO package lists regardless of selection. The installer’s selection-to-package behavior and persistence require redesign and verification before being called complete.

## Current test status

- `./tools/test`: per-script shell syntax, startup policy, Niri package/config and Noctalia pin assertions, QEMU GL and KVM/TCG fallback simulation, isolated `systemctl --root` disable test, and one-sample memory-collector CSV smoke test; no package/ISO/runtime build.
- `./tools/test-noctalia-package`: separate Docker/network test verifies the pinned signing key, package SHA-256, Trixie install dependencies, and CLI version/help; no GUI session.
- `./tools/build-niri-package`: built successfully in a fresh Debian Trixie/AMD64 container; all 195 upstream tests passed. A fresh Trixie install smoke test resolved declared dependencies and `niri --version` reported the pinned commit.
- Systemd user-unit verification: `systemd-analyze --user verify` remains unavailable in the build container, but the Noctalia unit was exercised in the fresh QEMU user manager; it started, reached `failed/timeout` at `TimeoutStopSec=5s` after Niri SIGKILL (no process remained), and started successfully again after relogin.
- `./build/build-iso`: not run for the Niri target; the default package/session configuration remains KDE.
- Niri smoke ISO QEMU run: UEFI login, Weston/llvmpipe rendering, Noctalia launcher, Foot mapping, VT resume and compositor-failure recovery were exercised; persistent installation and persistence across reboot were not.
- Native GPU, Waydroid, VM and 4/8/16 GiB idle-memory acceptance tests remain open.
