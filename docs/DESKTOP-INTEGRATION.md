# NextraOS Desktop Integration

## Philosophy

All supported applications should appear to the user as normal
desktop applications.

The user should not need to understand which compatibility layer
or virtualization technology is being used.

---

# Integration Levels

| Level | Technology | Experience | Seamless |
|---|---|---|---|
| L0 | Native Linux (APT) | Native | Complete |
| L1 | Flatpak | Sandboxed but native-feeling | Complete |
| L2 | Wine/Bottles/Proton | Windows compatibility | **Native GPU** |
| L3 | Waydroid | Android container | Complete |
| L4 | QEMU/KVM + OpenCore | macOS VM | **Full desktop only** |

---

# Windows Integration

## Architecture

```
Linux Desktop (KDE Plasma Wayland)
    │
    ├── Wine
    │   └── Windows applications (native GPU)
    │
    ├── Bottles (GUI management)
    │
    └── Proton (Steam gaming)
```

## Components

### Wine

Windows compatibility layer for running Windows applications.

- Native GPU acceleration (via Linux drivers)
- Low resource usage (2-4 GB RAM)
- Seamless window integration
- Good Office/browser compatibility

### Bottles

GUI management for Wine prefixes.

- Isolated Wine environments
- Easy configuration
- Flatpak distribution

### Proton

Steam's Wine-based gaming layer.

- Automatic game compatibility
- DirectX 9-11 support
- Anti-cheat compatibility (limited)

## File Sharing

| Path | Method | Description |
|---|---|---|
| /home/user/ | Native | Wine uses host filesystem |
| ~/.local/share/bottles/ | Bottles | Bottle storage |

## Limitations

- Some Windows applications do not work
- DirectX 12 support is limited
- Anti-cheat software may not work
- Fallback: macOS VM for incompatible apps

---

# Android Integration

## Architecture

```
Linux Desktop (Wayland)
    │
    └── Waydroid
            │
            ├── LXC container
            ├── Android (LineageOS based)
            ├── Wayland HWC (native rendering)
            └── Binder (IPC)
```

## Components

### Waydroid

Container-based Android environment.

- Full Android system in LXC container
- Native Wayland rendering
- Multi-window mode
- Application discovery
- Clipboard sharing

### Kernel Requirements

- binder module or binderfs
- ashmem module (older kernels)
- binderfs recommended for kernel 5.0+

## File Sharing

| Path | Method | Description |
|---|---|---|
| /home/user/Android/ | bind mount | Android-accessible folder |

## Limitations

- **Does not work in live mode** (installed system only)
- Kernel modules required
- Session auto-start configuration needed

---

# macOS Integration (Experimental)

## Architecture

```
Linux Desktop (KDE Plasma Wayland)
    │
    └── QEMU/KVM
        ├── OpenCore bootloader
        ├── macOS Recovery DMG
        ├── SPICE display
        └── systemd service
```

## Components

### QEMU/KVM

Direct QEMU/KVM virtualization (not Docker).

- Hardware-accelerated virtualization
- KVM acceleration via /dev/kvm
- systemd user service management

### OpenCore

Bootloader for non-Apple hardware.

- SMBIOS identity spoofing
- VM detection hiding (VMHide.kext)
- UEFI boot support

### SPICE

Display protocol for macOS VM.

- Clipboard sharing via spice-vdagent
- Dynamic resolution adjustment
- Audio forwarding
- Package: spice-gtk

## Desktop Integration Limitations

macOS has no RemoteApp equivalent protocol.

- **Full desktop access only** via SPICE
- Individual window forwarding is impossible
- Clipboard sharing via spice-vdagent

## File Sharing

| Path | Method | Description |
|---|---|---|
| /home/user/ | SPICE webdav | Host shared folder |

## Requirements

- AVX2-capable CPU (Intel Haswell 4th gen / AMD Zen, 2013+)
- KVM support
- 8GB+ RAM
- 64GB+ storage

## Legal

- macOS EULA restricts virtualization to Apple hardware
- NextraOS must document this restriction as experimental
- No proprietary Apple software should be redistributed

---

# Security

| Ecosystem | Isolation | File Sharing | Network |
|---|---|---|---|
| Windows (Wine) | Wine prefix | Native filesystem | Host network |
| Android | LXC container | bind mount | Bridge |
| macOS VM | QEMU/KVM | SPICE webdav | NAT |

## Principles

- VMs and containers must have explicit boundaries
- File sharing must be explicit (no unrestricted host access)
- Network isolation where possible
- No credential sharing without user consent

---

# Installer Integration

## Ecosystem Selection

Calamares packagechooserq module presents options:

```
NextraOS can run anything you want.
What type of apps do you want?

[x] Windows Apps
    Wine, Bottles, Proton (native GPU acceleration)

[ ] Android Apps
    Waydroid

[ ] macOS [Experimental]
    QEMU/KVM virtualization
```

## Post-Install Setup

Based on user selection:

- **Windows**: Install Wine, Bottles, Proton; configure desktop integration
- **Android**: Install Waydroid, configure kernel modules
- **macOS**: Configure QEMU/KVM, OpenCore, SPICE; download Recovery DMG

---

# Automation Scripts

## nextraos-vm-setup

Automated setup script for macOS VM.

### Usage

```bash
# Setup macOS VM
nextraos-vm-setup macos

# Generate config without starting VM
nextraos-vm-setup macos --no-start

# Generate template configuration file
nextraos-vm-setup --generate-config
```

### What It Does

1. **Pre-flight checks**: KVM, AVX2 (for macOS)
2. **Generate configurations**: QEMU arguments, systemd service
3. **Download Recovery DMG**: From Apple servers
4. **Prepare OpenCore**: Bootloader configuration
5. **Start VM**: Launch QEMU/KVM
6. **Create desktop entries**: KDE menu integration

### Configuration Files

All configurations are stored in `~/.config/nextraos/`:

```
~/.config/nextraos/
├── vm.conf                    # VM settings
├── macos/
│   ├── disk.qcow2            # macOS disk
│   ├── efivars               # UEFI variables
│   └── opencore/             # OpenCore configuration
└── systemd/
    └── user/
        └── nextraos-macos.service
```

## nextraos-vm-manager

VM lifecycle management via systemd.

### Usage

```bash
# Start macOS VM
nextraos-vm-manager start macos

# Stop macOS VM
nextraos-vm-manager stop macos

# Show status of all VMs
nextraos-vm-manager status

# Enable autostart
nextraos-vm-manager enable macos

# Disable autostart
nextraos-vm-manager disable macos
```

## nextraos-vm-tray

System tray applet for VM management.

### Features

- Start/stop macOS VM
- Quick access to SPICE viewer
- View VM logs
- Status indicator

### Usage

```bash
# Launch from terminal
nextraos-vm-tray

# Or find in KDE menu: System > NextraOS VM Manager
```

### Dependencies

```bash
sudo apt install spice-gtk
```

---

# Future Improvements

## Windows

- Additional Wine compatibility improvements
- Proton integration for more games
- Direct3D 12 support (when available)

## Android

- Kernel module auto-loading
- Application menu integration
- Clipboard improvements

## macOS

- SPICE improvements
- GPU passthrough (if Apple allows)
- Looking Glass integration (optional)

---

# References

- Wine: https://www.winehq.org/
- Bottles: https://usebottles.com/
- Proton: https://github.com/ValveSoftware/Proton
- Waydroid: https://github.com/waydroid/waydroid
- OpenCore: https://github.com/kholia/OSX-KVM
- SPICE: https://www.spice-space.org/
