# ADR 0004: Niri + Noctalia as the target desktop

- Status: Accepted for the NextraOS Tokyo direction; implementation is in progress
- Context: `addinfo.md` v0.1 defines Debian 13/Trixie, AMD64, Niri, and Noctalia v5 as the target Wayland desktop. The repository currently builds a KDE Plasma image, so this is a deliberate architecture change rather than a claim about the current ISO.

## Decision

Target a minimal Debian host with Niri as the Wayland compositor and Noctalia v5 as the desktop shell. Keep systemd, glibc, APT/dpkg, NetworkManager, and PipeWire. Do not bundle a full KDE or GNOME desktop as the default host environment.

Android and virtual machines remain optional execution environments. Waydroid initialization and guest-image downloads must happen only when the user explicitly starts Android support. Libvirt should use local systemd socket activation where available; VM processes must not start automatically just because the user logged in.

The idle goal is less than 1024 MiB of host memory in use, with 850 MiB as a development target, not a measured result. The goal is not permission to disable security features or misrepresent memory use.

## Rationale

- This follows the Tokyo project plan and prioritizes usable resources for applications and guests.
- Niri is a compositor, not a complete desktop; Noctalia supplies shell surfaces, while login, portals, audio, networking, app launching, and settings still need explicit integration and tests.
- The community-maintained Noctalia Debian Trixie APT archive recommends starting the shell from Niri. Its signing-key fingerprint and exact package hash were independently verified; a clean Trixie container accepted the signed index, installed the pinned package, and validated the current project TOML profile. The separate Niri smoke profile stages a version/origin-pinned source and key only for the live-build chroot. The KDE desktop package list remains the default, although shared Waydroid/libvirt activation hooks are being refactored separately. A headless Weston/llvmpipe QEMU run now verifies Niri output, Noctalia layers/launcher, Foot window rendering, VT resume and compositor-failure relogin; portals, playback, shutdown and persistence still need full acceptance. This is not Debian security support.
- Debian Trixie has no `niri` compositor package. The project-owned package for upstream v26.04 at commit `8ed0da44d974c32c6877d2f4630c314da0717ecb` built in a fresh Trixie/AMD64 container; all 195 upstream tests passed, and a separate install smoke test resolved dependencies and reported the pinned commit. The upstream tag is unsigned. Cargo dependency license review and full desktop acceptance remain open; the Niri package is included only in the reversible test profile, not the default live-build.
- The existing image still contains KDE-specific package lists, SDDM session defaults, and shell configuration. Those are migration work, not part of the accepted target architecture.

## Consequences

- The KDE-based image is a prototype and does not satisfy the Tokyo desktop target.
- The next desktop milestone must prove installation and session startup in QEMU before removing the current fallback or claiming a working Niri ISO.
- Desktop-specific applications (greeter, terminal, launcher, file manager, lock screen, portals, settings, and polkit agent) must be selected intentionally and measured rather than inherited from a task metapackage.
- Memory results must record the test profile and use `MemTotal - MemAvailable` as the primary idle metric. Report PSS, zram, swap, PSI, and boot timing as companion data.

## Upstream references

- Niri project and status: <https://github.com/niri-wm/niri>
- Niri build and packaging guidance: <https://niri-wm.github.io/niri/Getting-Started.html>
- Debian package search for Niri: <https://packages.debian.org/search?keywords=niri&searchon=names&suite=trixie&section=all>
- Noctalia v5 installation (including Debian): <https://docs.noctalia.dev/noctalia/getting-started/installation/>
- Noctalia compositor setup for Niri: <https://docs.noctalia.dev/noctalia/compositor-settings/niri/>
- Tokyo project requirements: `addinfo.md`
