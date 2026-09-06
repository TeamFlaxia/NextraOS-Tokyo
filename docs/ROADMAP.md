# NextraOS Roadmap

## Phase 0 — Research

Status: Complete

Research:

- Debian Trixie
- live-build
- KDE Plasma
- Wayland
- PipeWire
- NetworkManager
- Wine
- Bottles
- Proton
- Waydroid
- QEMU
- KVM
- Docker
- Podman
- dockur/windows
- dockur/macos
- WinApps
- WinBoat
- application integration

Deliverable:

    docs/RESEARCH.md

---

# Phase 1 — Minimal ISO

Status: Complete (2026-09-06)

Goal:

Boot NextraOS in QEMU.

Components:

- Debian Trixie (13.0)
- KDE Plasma 6.3.6 (Wayland)
- SDDM 0.21.0
- PipeWire 1.4.2 + WirePlumber 0.5.8
- NetworkManager 1.52.1
- Konsole 25.04.2 (terminal)
- Dolphin 25.04.3 (file manager)
- KDE System Settings (via kde-standard)
- Firefox ESR 140.15.0
- Docker (docker.io 26.1.x + docker-compose)
- Flatpak + xdg-desktop-portal-kde
- VSCodium (codium, via official repo)

Success criteria:

- ISO builds ✅
- ISO boots ✅
- graphical session starts ✅
- networking works ✅ (NetworkManager icon in tray)
- audio works ⚠️ (PipeWire installed, not tested interactively)
- shutdown/reboot works ⚠️ (standard KDE, not tested interactively)

Verification date: 2026-09-06

Tested in QEMU with UEFI boot (OVMF), 4GB RAM, 2 CPUs, KVM.

Note: QEMU monitor input does not reach the Wayland compositor
reliably, so interactive app-launch testing requires a graphical
display (VNC viewer, Spice, or local display).

---

# Phase 2 — Installer

Implement:

- welcome screen
- user creation
- language
- keyboard
- timezone
- hardware detection
- network detection
- ecosystem selection
- starter applications
- disk selection
- installation

Success criteria:

A fresh QEMU VM can install NextraOS from the ISO.

---

# Phase 3 — Native Application Layer

Implement:

- APT
- Flatpak
- Software Center
- application discovery
- desktop integration

Starter kit:

- Firefox
- GIMP
- VLC
- VSCodium

---

# Phase 4 — Windows Compatibility

Implement:

- Wine
- Bottles
- Proton
- executable handling
- desktop integration

Proof of concept:

    install.exe
        |
        v
    compatibility resolver
        |
        v
    Wine

---

# Phase 5 — Android

Integrate:

- Waydroid
- APK installation
- application discovery
- desktop entries

---

# Phase 6 — Windows VM

Investigate:

- QEMU
- KVM
- Docker
- Podman
- dockur/windows
- WinApps
- WinBoat

Goal:

Expose selected Windows applications as normal desktop applications.

---

# Phase 7 — Unified Compatibility Resolver

Build:

    Nextra Compatibility Resolver

It should select:

- native
- Flatpak
- Wine
- Proton
- Waydroid
- Windows VM
- macOS VM

based on application metadata and host capabilities.

---

# Phase 8 — macOS Experimental

Research and prototype:

- QEMU/KVM
- dockur/macos
- hardware requirements
- legal restrictions

No proprietary images should be redistributed without permission.

---

# Phase 9 — Production Hardening

Improve:

- security
- updates
- rollback
- recovery
- logging
- diagnostics
- resource management
- installer reliability
- compatibility database
- documentation

---

# Long-Term Goal

A user should be able to search for an application and launch it
without needing to understand which operating system the application
was originally designed for.