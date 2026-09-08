# NextraOS

> One Desktop. Every App.

NextraOS is an experimental Debian-based desktop Linux distribution
designed to provide a unified Wayland desktop for applications from
multiple operating-system ecosystems.

## Vision

NextraOS combines:

- Linux applications
- Windows applications
- Android applications
- experimental macOS applications

into one desktop environment.

The user should not need to care whether an application is running
natively, through a compatibility layer, inside a container, or inside
a virtual machine.

## Target Stack

- Debian Trixie
- KDE Plasma
- Wayland
- PipeWire
- NetworkManager
- APT
- Flatpak
- VSCodium
- Wine / Bottles / Proton
- Waydroid
- QEMU / KVM

The actual implementation may change as research progresses.

## Design Principle

NextraOS does not attempt to recreate other operating systems.

It integrates existing open-source technologies into one desktop.

## Execution Model

### Linux

Native Linux applications are preferred.

### Android

Waydroid provides the Android execution environment.

### Windows

The preferred order is:

1. Wine
2. Bottles
3. Proton where appropriate
4. Windows with KVM

### macOS

Experimental virtualization is planned where technically and legally
appropriate.

## Hardware

### Limited Mode

- AMD64 CPU
- 2 GB RAM
- 32 GB storage

### Full-Feature Minimum

- AVX2-capable CPU for the complete virtualization stack
- 8 GB RAM
- 128 GB storage
- hardware virtualization

### Recommended

- Intel Core 7th generation or newer
- AMD Ryzen 5th generation or newer
- 16 GB RAM+
- 512 GB SSD+
- NVMe preferred

## Development

The first development target is a QEMU-runnable Live ISO.

### Prerequisites

- Debian Trixie (or compatible) host
- `live-build` package
- `qemu-system-x86` and `ovmf` for testing
- Root access for building (debootstrap/chroot)
- Network access during build

### Build

    ./build/build-iso

This produces `dist/nextraos-live-amd64.iso`.

### Run in QEMU (UEFI)

    ./tools/run-qemu

### Run in QEMU (BIOS)

    ./tools/run-qemu-bios

## Project Status

| Phase | Status |
|---|---|
| Phase 0 — Research | ✅ Complete |
| Phase 1 — Minimal ISO | ✅ Complete (2026-09-06) |
| Phase 2 — Installer | Pending |
| Phase 3 — Native Application Layer | Pending |
| Phase 4 — Windows Compatibility | Pending |
| Phase 5 — Android | Pending |
| Phase 6 — Windows VM | Pending |
| Phase 7 — Compatibility Resolver | Pending |
| Phase 8 — macOS Experimental | Pending |
| Phase 9 — Production Hardening | Pending |

Phase 1 produces a bootable Debian Trixie-based KDE Plasma 6
Wayland Live ISO with Docker, Flatpak, and VSCodium included.
Boots successfully in QEMU with UEFI.

See:

- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/RESEARCH.md`
- `docs/DEVELOPMENT.md`
