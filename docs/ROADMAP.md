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
- Waydroid
- QEMU
- KVM
- Wine
- Bottles
- Proton
- SPICE
- OpenCore
- systemd
- desktop integration

Deliverable:

    docs/RESEARCH.md
    docs/DESKTOP-INTEGRATION.md

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

- Calamares-based GUI installer
- welcome screen
- user creation
- language
- keyboard
- timezone
- hardware detection
- network detection
- ecosystem selection (packagechooserq)
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

# Phase 4 — Android

Integrate:

- Waydroid
- Kernel module setup (binderfs)
- APK installation
- application discovery
- desktop entries
- clipboard sharing
- file sharing

Success criteria:

Android apps run as native Wayland windows on NextraOS.

Note: Waydroid requires installed system (not live mode).

---

# Phase 5 — Windows Compatibility

Implement:

- Wine (Windows compatibility layer)
- Bottles (Wine GUI management)
- Proton (Steam gaming)
- Desktop integration (.desktop files)
- MIME type registration (.exe, .msi)
- Application menu integration
- Starter kit:
  - Firefox
  - GIMP
  - VLC
  - VSCodium
  - LibreOffice

Success criteria:

Windows applications run natively on NextraOS with GPU
acceleration.

Architecture:

    Linux Desktop (KDE Plasma Wayland)
        │
        ├── Wine
        │   └── Windows applications (native GPU)
        │
        ├── Bottles (GUI management)
        │
        └── Proton (Steam gaming)

Limitations:

- Some Windows applications do not work under Wine
- DirectX 12 support is limited
- Anti-cheat software may not work
- Fallback: macOS VM for incompatible applications

---

# Phase 6 — macOS Experimental

Implement:

- QEMU/KVM via libvirt (same management as Windows VM)
- OpenCore bootloader
- SPICE protocol integration
- spice-vdagent (clipboard, resolution)
- systemd user services
- Automated Recovery DMG download
- File sharing (SPICE webdav)

Success criteria:

macOS runs in a VM accessible via SPICE.

Architecture:

    Linux Desktop (KDE Plasma Wayland)
        │
        └── libvirt / QEMU/KVM
            ├── OpenCore bootloader
            ├── macOS Recovery DMG
            ├── SPICE display
            └── systemd service

Note:

- AVX2 required (Intel Haswell 4th gen+, 2013+)
- Full desktop only (no seamless windows)
- Experimental status
- macOS EULA restricts virtualization to Apple hardware

---

# Phase 7 — VM Lifecycle Management

Implement:

- VM suspend/resume (`virsh save` / `virsh restore`)
- VM snapshots (`virsh snapshot-create-as`)
- Auto-suspend on application exit (configurable grace period)
- Agent ready detection (polling instead of fixed sleep)
- CPU pinning for VM cores
- I/O optimization (virtio-scsi, cache=none)
- Memory balloon driver
- Headless mode for execute-only workloads
- systemd integration for login-time autostart
- System suspend hook (auto-suspend VMs on systemctl suspend)

Success criteria:

VMs consume host resources only when actively in use. Applications
launched via `nextraos-vm execute` auto-suspend after exit.

Configuration:

    # ~/.config/nextraos/vm.conf
    VM_AUTO_SUSPEND=true
    VM_SUSPEND_GRACE_PERIOD=30
    VM_SUSPEND_ON_SYSTEM_SUSPEND=true

---

# Phase 8 — Production Hardening

Improve:

- security
- updates
- rollback
- recovery
- logging
- diagnostics
- resource management
- installer reliability
- documentation

---

# Long-Term Goal

A user should be able to search for an application and launch it
without needing to understand which operating system the application
was originally designed for.

Supported ecosystems:

- Native Linux (APT, Flatpak)
- Windows (Wine, Bottles, Proton)
- Android (Waydroid)
- macOS (experimental, QEMU/KVM)
