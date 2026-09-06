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

First build takes 15-45 minutes depending on network speed.
Subsequent builds use the download cache and are faster.

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

The VM provides:

- UEFI via OVMF
- 4 GB RAM
- 2 CPUs (host passthrough)
- KVM acceleration
- virtio-vga display
- virtual network (user-mode, SSH forwarded to port 2222)
- USB tablet and keyboard

For interactive testing, connect a VNC viewer to `localhost:5999`
or change the display backend in the script.

---

# Install Test

    ./tools/run-qemu-install

This should boot the ISO with a blank virtual disk.

The test should verify:

- installer starts
- hardware detection works
- disk detection works
- networking works
- installation completes
- installed system boots

---

# Test

    ./tools/test

The test framework should eventually include:

- shell tests
- installer tests
- image tests
- boot tests
- package tests
- desktop tests

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