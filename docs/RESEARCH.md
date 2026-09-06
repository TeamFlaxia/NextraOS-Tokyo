# NextraOS Research

This document records technical research.

Research must be updated as upstream projects change.

---

# Debian Trixie

NextraOS targets Debian Trixie.

The initial ISO build should use Debian's native live-build tooling.

Reference:

https://manpages.debian.org/trixie/live-build/

Decision:

Use Debian tooling rather than creating a custom Linux distribution
builder.

Implementation (Stage 1):

- Host: live-build package from Debian Trixie
- Build must run as root (debootstrap, chroot, mount)
- `auto/config` stores all `lb config` options as single source of truth
- `config/package-lists/*.list.chroot` for package selection
- `config/includes.chroot/` for file overlays (SDDM autologin, etc.)
- Output: `iso-hybrid` image (BIOS + UEFI bootable)
- QEMU testing: OVMF firmware at `/usr/share/OVMF/OVMF_CODE_4M.fd`

Build command:

    ./build/build-iso

Run in QEMU:

    ./tools/run-qemu dist/nextraos-live-amd64.iso

Key packages:

    live-task-kde          # Live KDE metapackage (trixie)
    task-kde-desktop       # KDE Plasma desktop (Dolphin, Konsole, etc.)
    firefox-esr            # Browser (Debian main)
    pipewire               # Audio server
    wireplumber            # PipeWire session manager
    pipewire-pulse         # PulseAudio compatibility
    network-manager        # Network management
    plasma-nm              # KDE NetworkManager widget
    spice-vdagent          # QEMU guest integration

---

# Waydroid

Waydroid provides a container-based Android environment on GNU/Linux.

It uses Linux namespaces and provides a full Android system environment.

Reference:

https://github.com/waydroid/docs

Decision:

Use Waydroid rather than implementing an Android compatibility layer.

---

# Wine

Wine provides a compatibility layer for Windows applications.

NextraOS should use upstream Wine where possible.

Research required:

- Wayland support
- Vulkan
- audio
- filesystem integration
- application compatibility
- multi-monitor behavior

Decision:

Use upstream Wine.

---

# Bottles

Bottles should be evaluated as the user-facing environment manager
for Wine.

Research:

- Flatpak integration
- runners
- prefixes
- application management
- CLI/API integration

Decision:

Prefer integration over reimplementation.

---

# Proton

Proton should be evaluated for applications where Proton provides
better compatibility than ordinary Wine.

Particularly relevant:

- games
- DirectX applications
- Steam-related software

Decision:

Integrate where technically useful.

---

# dockur/windows

dockur/windows provides a container-based Windows VM architecture
using KVM/QEMU underneath.

It supports:

- automatic installation
- KVM acceleration
- configurable CPU/RAM/storage
- USB passthrough
- folder sharing
- networking
- Windows application desktop integration projects

The upstream project documents Docker or Podman on Linux with KVM
support as a supported architecture.

Reference:

https://github.com/dockur/windows

Important:

The fact that the VM is exposed through a container interface does
not mean that Windows is executing as a normal Linux container.

NextraOS must treat it as a VM/virtualization backend.

Decision:

Evaluate dockur/windows as a Windows VM backend.

Do not blindly embed it into the base system.

---

# dockur/macos

dockur/macos provides a QEMU/KVM-based macOS virtualization environment
with a container interface.

The upstream documentation lists:

- KVM
- AVX2-capable processors
- configurable CPU/RAM/storage
- USB passthrough
- folder sharing

Reference:

https://github.com/dockur/macos

Decision:

Experimental research only.

Legal and hardware restrictions must be evaluated before distribution.

---

# QEMU

QEMU is the primary virtualization technology to evaluate.

Use KVM acceleration whenever available.

Requirements:

- `/dev/kvm`
- CPU virtualization extensions
- appropriate permissions

Implementation (Stage 1):

- QEMU 10.0.8 tested successfully
- UEFI via OVMF (`/usr/share/ovmf/OVMF.fd`)
- VNC display (`:99`) for headless testing
- User-mode networking with SSH port forward (2222)
- Known limitation: QEMU monitor input (`sendkey`,
  `mouse_move`, `mouse_button`) does not reach the
  Wayland compositor (KWin) reliably. For interactive
  desktop testing, use a VNC viewer or Spice client.

---

# KVM

KVM is required for practical VM performance.

NextraOS should detect:

- Intel VT-x
- AMD SVM
- `/dev/kvm`

and expose the result to the installer.

---

# Docker / Podman

Container technology may be used as an integration mechanism for
virtualization backends.

However, NextraOS should not assume:

    container == lightweight process

Some containerized projects are effectively management layers
around QEMU/KVM virtual machines.

This distinction must be preserved in the architecture.

Implementation (Stage 1):

- `docker.io` from Debian main (no external repository needed)
- `docker-compose` for compose file support
- dockur/windows and dockur/macos confirmed compatible with
  docker.io 26.1.x (Debian Trixie)
- No docker-ce required
- Live user added to docker group for passwordless access
- KVM passthrough (/dev/kvm) required for dockur containers

---

# Flatpak

Flatpak provides additional application distribution.

Implementation (Stage 1):

- `flatpak` package from Debian main
- `xdg-desktop-portal` and `xdg-desktop-portal-kde` for
  KDE Plasma integration
- Flathub repository can be added by the user or installer

---

# VSCodium

VSCodium provides a community-built VS Code without Microsoft
telemetry.

Implementation (Stage 1):

- Not in Debian repos; installed via official VSCodium APT repo
- Repository: https://repo.vscodium.dev/deb
- Package: `codium`
- Added via chroot hook during ISO build
- Installed size: ~367 MB

---

# KDE Plasma

KDE Plasma is the primary desktop environment.

Target:

- Wayland session
- modern KDE Plasma
- standard Linux desktop integration

NextraOS should minimize modifications to Plasma.

---

# Network-First Installation

The ISO should remain relatively small.

The installer should download:

- optional compatibility runtimes
- starter applications
- VM support
- Android support
- optional packages

from configured repositories.

The installer must provide useful failure messages if networking
is unavailable.

---

# Research Policy

Every major dependency must be reviewed periodically.

Research should include:

- upstream activity
- release status
- security issues
- licensing
- compatibility
- supported architectures
- maintenance status

Never freeze assumptions indefinitely.