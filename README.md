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

Windows applications run in a Windows VM via QEMU/KVM.

1. Windows with KVM

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
| Phase 2 — Installer | ✅ Complete (2026-09-11) |
| Phase 3 — Native Application Layer | ✅ Complete (2026-09-11) |
| Phase 4 — Android | ✅ Complete (2026-09-11) |
| Phase 5 — Windows VM Integration | ✅ Complete (2026-09-11) |
| Phase 6 — macOS Experimental | ✅ Complete (2026-09-11; experimental) |
| Phase 7 — VM Lifecycle Management | ⚠️ Partially complete (2026-09-11) |
| Phase 8 — Production Hardening | ✅ Complete (2026-09-11) |
| Compatibility resolver | Long-term goal; not implemented |

This summary follows the phase statuses in [docs/ROADMAP.md](docs/ROADMAP.md).
“Complete” reflects the roadmap's stated scope, not production readiness;
see the roadmap for verification details and known limitations. The compatibility
resolver is a long-term goal, not a numbered or completed phase.

Phase 1 delivered a bootable Debian Trixie-based KDE Plasma 6
Wayland Live ISO with Flatpak and VSCodium included. It was tested in
QEMU with UEFI; see [docs/ROADMAP.md](docs/ROADMAP.md#L30) for test scope.

See:

- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/RESEARCH.md`
- `docs/DEVELOPMENT.md`
