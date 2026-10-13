# NextraOS Tokyo

> One Desktop. Every App.
>
> Minimal Host. Maximum Guest Performance.

NextraOS Tokyo is an experimental Debian-based Wayland OS project. It aims to keep the host lean and persistent while launching native Linux apps, Android apps through Waydroid, and virtual machines through QEMU/KVM.

## Target architecture

- Debian 13 (Trixie), AMD64
- Niri compositor + Noctalia v5 shell
- systemd, APT/dpkg, NetworkManager, PipeWire/WirePlumber
- Persistent installed system; Android and VMs start on demand

The idle target is below 1024 MiB of host memory in use; 850 MiB is a development goal. **Neither target is verified yet.** The 4/8/16 GB profiles are test profiles, not a promise that heavy guests can run simultaneously. See [hardware guidance](docs/MEMORY-BENCHMARK.md).

## Project status

The repository's default live-build path remains an older KDE Plasma prototype; its historical QEMU results do not validate the Tokyo target. The pinned Niri package built in a fresh Trixie/AMD64 container, passed 195 upstream tests, and installed with a pinned-version smoke check. Noctalia v5's Trixie package signing key, hash, install, CLI and current TOML profile were smoke-tested; the Niri KDL profile passes the pinned compositor's validator. A freshly rebuilt reversible Niri smoke ISO booted through its UEFI live menu to tuigreet, accepted the serial `user`/`live` login, and starts Niri, Noctalia, PipeWire/WirePlumber and NetworkManager. On this host, which has no `/dev/dri`, `/dev/kvm`, usable GLX or ALSA default PCM, a headless Weston/llvmpipe GL bridge with QEMU `virtio-vga-gl` under TCG verifies Niri's `Virtual-1` 1280×800 output, Noctalia bar/launcher, and a mapped Foot window; see the [launcher screenshot](docs/assets/niri-weston-launcher.png). On the fresh ISO, VT resume worked without EAGAIN; after compositor SIGKILL, greetd returned, systemd removed the Noctalia process at its five-second stop timeout (`Result=timeout`), and relogin restarted both. Stage 1 is still incomplete: portal workflows, actual audio playback, shell-driven shutdown/logout, installation persistence, and memory targets remain open, and the software-rendered path is not native-GPU performance evidence. The root KDE desktop package list remains selected, while shared Waydroid/libvirt hooks have separate on-demand activation changes. Do not treat the KDE ISO as the Tokyo target or as production-ready.

See the [roadmap](docs/ROADMAP.md), [Niri desktop ADR](docs/adr/0004-niri-noctalia-desktop.md), [test-profile ADR](docs/adr/0005-reversible-niri-test-profile.md), [research](docs/RESEARCH.md), and [development guide](docs/DEVELOPMENT.md).

## Host desktop profile

The opt-in [Flow profile](desktop/flow/README.md) captures the tested physical
host's bottom taskbar/search UI, window controls, WezTerm, Japanese input and
portal-session fixes. It includes the source patch required by Noctalia
v5.2.1, a reversible dotfile installer and source pins. VM configuration and
personal application data are excluded. This profile does not replace the
existing ISO prototype or extend its validation claims.

## Build and test

The standard `./build/build-iso` still builds the KDE prototype. The isolated test profile requires the pinned Niri `.deb` first and does not modify the default package list:

```sh
./tools/build-niri-package
./build/build-niri-test-iso
./tools/run-qemu dist/nextraos-niri-test-amd64.iso
```

The live-build path is Debian Trixie/AMD64 and needs network access plus root privileges for debootstrap/chroot. The smoke ISO clean-boots to the greeter and accepts the live `user`/`live` login. Direct GTK/standard-VGA non-GL modes are only login/diagnostic paths. For hosts without GLX, follow the headless Weston/llvmpipe procedure in [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) to test `virtio-vga-gl` under QEMU/TCG and capture the guest desktop with `niri msg action screenshot-screen`; this path is offscreen and software-rendered. Portal D-Bus activation, basic guest networking, Noctalia/Foot rendering, VT resume and compositor-failure relogin have been exercised. Portal workflows, actual audio playback, shell-driven shutdown/logout, persistence, and 4/8/16 GiB idle-memory targets remain open. Run `./tools/test` for repository regression/smoke checks.

## Memory measurement

After booting an installed test image, run:

```sh
./tools/measure-idle-memory --output results/idle-4g-run1.csv
```

It samples at 5, 30, and 60 minutes after boot and writes a metadata sidecar. Repeat cold boots at 4, 8, and 16 GiB under the fixed conditions in [the benchmark guide](docs/MEMORY-BENCHMARK.md). Measurements are evidence, not a claim that the target has been met.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Installer](docs/INSTALLER.md)
- [Research](docs/RESEARCH.md)
- [Security](docs/SECURITY.md)
- [Memory benchmark](docs/MEMORY-BENCHMARK.md)
