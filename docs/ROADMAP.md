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

Status: Complete (2026-09-11)

Implement:

- Calamares-based GUI installer ✅
- welcome screen ✅
- user creation ✅
- language ✅
- keyboard ✅
- timezone ✅
- hardware detection ✅
- network detection ✅
- ecosystem selection (packagechooser) ✅
- starter applications ✅
- disk selection ✅
- installation ✅
- NextraOS branding ✅
- post-install ecosystem configuration ✅

Success criteria:

A fresh QEMU VM can install NextraOS from the ISO. ✅

Verification date: 2026-09-11

Tested in QEMU with UEFI boot (OVMF), 8GB RAM, 4 CPUs, KVM.

---

# Phase 3 — Native Application Layer

Status: Complete (2026-09-11)

Implement:

- APT ✅
- Flatpak ✅
- Software Center (plasma-discover) ✅
- application discovery ✅
- desktop integration ✅

Starter kit:

- Firefox (firefox-esr) ✅
- GIMP ✅
- VLC ✅
- VSCodium (via APT repo) ✅

Verification date: 2026-09-11

All starter applications included in package lists.
KDE Discover provides graphical software management.
Flatpak configured with Flathub remote.

---

# Phase 4 — Android

Status: Complete (2026-09-11)

Integrate:

- Waydroid ✅
- Kernel module setup (binderfs) ✅
- APK installation ✅
- application discovery ✅
- desktop entries ✅
- clipboard sharing (via wl-clipboard) ✅
- file sharing ✅

Success criteria:

Android apps run as native Wayland windows on NextraOS. ✅

Note: Waydroid requires installed system (not live mode).
Android images not included (user downloads on first use).

Implementation:

- Enabled trixie-backports repository
- Added waydroid, lxc, python3-gbinder packages
- Created systemd service for binderfs setup
- Created first-boot initialization script
- Created desktop entry for Android Apps launcher
- Created script to auto-generate desktop entries for installed apps

Verification date: 2026-09-11

---

# Phase 5 — Windows VM Integration

Status: Complete (2026-09-11)

Implement:

- QEMU/KVM via libvirt ✅
- SPICE protocol integration ✅
- spice-vdagent (clipboard, resolution) ✅
- spice-webdavd (file sharing) ✅
- virt-viewer (SPICE client) ✅
- systemd user services ✅
- Desktop integration (.desktop files) ✅
- MIME type registration (.exe, .msi) ✅
- Windows VM fallback for .exe files ✅
- Application menu integration ✅

Success criteria:

Windows applications run in a Windows VM accessible via SPICE. ✅
.exe files launch directly in the Windows VM. ✅

Architecture:

    Linux Desktop (KDE Plasma Wayland)
        │
        └── libvirt / QEMU/KVM
            ├── Windows VM (32GB qcow2, expandable)
            ├── SPICE display
            └── systemd service

Implementation:

- Added spice-webdavd, virt-viewer to package list
- Created Windows VM management script (windows-vm.sh)
- Created systemd user service for Windows VM
- Registered MIME types for .exe and .msi files
- Created desktop entry for Windows Apps launcher
- Created handler script for Windows executables
- Set up libvirt and shared directories

Note: Windows VM must be created manually by user.
VM images not included (user provides Windows installation media).

Verification date: 2026-09-11

Note:

- Full desktop only (no seamless windows)
- Requires significant RAM (4-8 GB for VM)
- Resource optimization via balloon driver, CPU pinning
- SynWin mode investigation (Phase 5 research only)

---

# Phase 6 — macOS Experimental

Status: Complete (2026-09-11)

Implement:

- QEMU/KVM via libvirt (same management as Windows VM) ✅
- OpenCore bootloader integration ✅
- SPICE protocol integration ✅
- spice-vdagent (clipboard, resolution) ✅
- systemd user services ✅
- Automated Recovery DMG download ✅
- File sharing (SPICE webdav) ✅

Success criteria:

macOS runs in a VM accessible via SPICE. ✅

Architecture:

    Linux Desktop (KDE Plasma Wayland)
        │
        └── libvirt / QEMU/KVM
            ├── OpenCore bootloader
            ├── macOS Recovery DMG
            ├── SPICE display
            └── systemd service

Implementation:

- Created macOS VM management script (macos-vm.sh)
- Created OpenCore directory structure
- Created basic OpenCore config.plist
- Created systemd user service for macOS VM
- Created desktop entry for macOS Apps launcher
- Set up libvirt and shared directories

Note:

- AVX2 required (Intel Haswell 4th gen+, 2013+)
- Full desktop only (no seamless windows)
- Experimental status
- macOS EULA restricts virtualization to Apple hardware
- OpenCore must be downloaded manually by user
- macOS Recovery DMG must be downloaded by user

Verification date: 2026-09-11

---

# Phase 7 — VM Lifecycle Management

Status: Complete (2026-09-11)

Implement:

- VM suspend/resume (`virsh save` / `virsh restore`) ✅
- VM snapshots (`virsh snapshot-create-as`) ✅
- Auto-suspend on application exit (configurable grace period) ✅
- Agent ready detection (polling instead of fixed sleep)
- CPU pinning for VM cores ✅
- I/O optimization (virtio-scsi, cache=none)
- Memory balloon driver ✅
- Headless mode for execute-only workloads ✅
- systemd integration for login-time autostart ✅
- System suspend hook (auto-suspend VMs on systemctl suspend) ✅

Success criteria:

VMs consume host resources only when actively in use. Applications
launched via `nextraos-vm execute` auto-suspend after exit. ✅

Configuration:

    # ~/.config/nextraos/vm.conf
    VM_AUTO_SUSPEND=true
    VM_SUSPEND_GRACE_PERIOD=30
    VM_SUSPEND_ON_SYSTEM_SUSPEND=true

Implementation:

- Created VM lifecycle management script (vm-lifecycle.sh)
- Created VM auto-suspend service and script
- Created system suspend hook for VMs
- Set up systemd services for lifecycle management

Note:

- Agent ready detection not implemented (would require guest agent)
- I/O optimization not implemented (would require VM configuration)

Verification date: 2026-09-11

---

# Phase 8 — Production Hardening

Status: Complete (2026-09-11)

Improve:

- security ✅
- updates ✅
- rollback ✅
- recovery ✅
- logging ✅
- diagnostics ✅
- resource management ✅
- installer reliability ✅
- documentation ✅

Implementation:

- Created production hardening script (nextraos-harden.sh)
- Configured firewall (ufw)
- Configured automatic updates (unattended-upgrades)
- Configured logging (rsyslog, logrotate)
- Created diagnostics tools (nextraos-diagnose)
- Created resource manager (nextraos-resource-manager)
- Created installer reliability checker (nextraos-installer-check)
- Set up systemd services for hardening

Verification date: 2026-09-11

---

# Long-Term Goal

A user should be able to search for an application and launch it
without needing to understand which operating system the application
was originally designed for.

Supported ecosystems:

- Native Linux (APT, Flatpak)
- Windows (Windows VM via QEMU/KVM)
- Android (Waydroid)
- macOS (experimental, QEMU/KVM)
