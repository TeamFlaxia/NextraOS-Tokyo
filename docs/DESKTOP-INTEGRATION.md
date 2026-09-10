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
| L2 | Waydroid | Android container | Complete |
| L3 | libvirt/QEMU/KVM | Windows/macOS VM | **Full desktop only** |

---

# Windows Integration

## Architecture

```
Linux Desktop (KDE Plasma Wayland)
    │
    └── libvirt / QEMU/KVM
        ├── Windows VM
        ├── SPICE display
        └── systemd service
```

## Components

### QEMU/KVM via libvirt

Windows applications run in a full Windows VM managed by libvirt.

- Hardware-accelerated virtualization
- KVM acceleration via /dev/kvm
- `virt-install` for VM creation
- `virsh` for lifecycle management
- systemd user service management

### SPICE

Display protocol for Windows VM.

- Clipboard sharing via spice-vdagent
- Dynamic resolution adjustment
- Audio forwarding
- Package: spice-gtk

## File Sharing

| Path | Method | Description |
|---|---|---|
| /home/user/ | SPICE webdav | Host shared folder |

## Limitations

- Full desktop only (no seamless windows)
- Requires significant RAM (4-8 GB for VM)
- Resource optimization via balloon driver, CPU pinning

## SynWin Mode (Experimental)

SynWin mode allows running the same Windows installation on both
bare metal (dual-boot) and in a VM under Linux.

### Architecture

```
Bare Metal Boot                    VM Boot (under Linux)
    │                                   │
    └─ Windows boots directly           └─ synwin_prep creates synthetic disk
       on hardware                         │
                                           ├─ Maps ESP, MSR, Windows partitions
                                           ├─ Copies preamble (MBR+GPT)
                                           └─ Creates network bridge
                                               │
                                               └─ QEMU/KVM boots Windows
                                                  from synthetic disk
```

### Components

#### Synthetic Disk

Linux device mapper creates a "synthetic disk" that maps real
Windows partitions:

- **ESP** (EFI System Partition) - mapped read/write
- **MSR** (Microsoft Reserved) - mapped read/write
- **Windows** - mapped read/write
- **Preamble** (MBR+GPT) - copied to image file

#### Hardware Spoofing

Windows uses hardware attributes for license activation. SynWin
spoofs these to match bare metal:

- PC make, model, serial number
- Mainboard make, model, serial number
- Hard disk serial number

#### Network Bridge

TAP device bridges Windows VM to host network:

- Separate IP from Linux host
- Separate MAC address (LAA)
- DHCP reservation recommended

### Usage

```bash
# Detect Windows installation on bare metal
nextraos-vm detect-windows

# Create synthetic disk
nextraos-vm create-syndisk

# Start Windows in SynWin mode
nextraos-vm start windows --synwin

# Cleanup after shutdown
nextraos-vm done-syndisk
```

### Limitations

- No Secure Boot support in VM
- No TPM support in VM
- BitLocker with TPM keys fails (PIN/USB key may work)
- Fast Startup must be disabled in Windows
- VirtIO display drivers may need pre-installation
- GPT/UEFI required (no MBR/BIOS support)

### Status

**Phase 5: Investigation only**
**Phase 7: Implementation (if viable)**

Reference: https://www.dragonhawk.org/tech/synwin/

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
    └── libvirt / QEMU/KVM
        ├── OpenCore bootloader
        ├── macOS Recovery DMG
        ├── SPICE display
        └── systemd service
```

## Components

### libvirt / QEMU/KVM

QEMU/KVM virtualization managed via libvirt (same as Windows VM).

- Hardware-accelerated virtualization
- KVM acceleration via /dev/kvm
- `virt-install` for VM creation
- `virsh` for lifecycle management (start, stop, suspend, snapshot)
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
- 32GB+ storage (expandable)

## Legal

- macOS EULA restricts virtualization to Apple hardware
- NextraOS must document this restriction as experimental
- No proprietary Apple software should be redistributed

---

# Security

| Ecosystem | Isolation | File Sharing | Network |
|---|---|---|---|
| Windows VM | libvirt/QEMU/KVM | SPICE webdav | NAT |
| Android | LXC container | bind mount | Bridge |
| macOS VM | libvirt/QEMU/KVM | SPICE webdav | NAT |

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
    Windows VM (QEMU/KVM)

[ ] Android Apps
    Waydroid

[ ] macOS [Experimental]
    QEMU/KVM virtualization
```

## Post-Install Setup

Based on user selection:

- **Windows**: Configure libvirt/QEMU/KVM, systemd services
- **Android**: Install Waydroid, configure kernel modules
- **macOS**: Configure libvirt/QEMU/KVM, OpenCore, SPICE; download Recovery DMG

---

# VM Lifecycle Management

## Suspend / Resume

VMs are suspended via `virsh save` and resumed via `virsh restore`.

```bash
# Suspend a VM (saves state to disk, frees RAM)
nextraos-vm suspend windows
nextraos-vm suspend macos

# Resume a VM (restores from latest save file)
nextraos-vm resume windows
nextraos-vm resume macos
```

Save files are stored in:

```
~/.local/share/nextraos/vms/<vm>/save/
```

## Snapshots

```bash
# Create a snapshot
nextraos-vm snapshot windows "before-update"
nextraos-vm snapshot macos "clean-install"

# List snapshots
nextraos-vm list-snapshots windows

# Restore a snapshot
nextraos-vm restore-snapshot windows "before-update"

# Delete a snapshot
nextraos-vm delete-snapshot windows "before-update"
```

---

# Auto-Suspend Behavior

## Overview

When an application is launched via `nextraos-vm execute`, NextraOS
tracks the application lifecycle and automatically suspends the VM
after the application exits and a configurable grace period.

## Automatic Lifecycle

The VM lifecycle is fully automatic:

```
nextraos-vm execute <vm> <app>
    │
    ├── VM running?
    │   └── Yes → Execute app
    │
    ├── VM not running?
    │   ├── Saved state exists? → Resume from saved state
    │   └── No saved state → Start fresh
    │
    ├── Wait for agent/SSH ready
    │
    ├── Execute app
    │   ├── Windows: guest-exec via qemu-guest-agent (track PID)
    │   └── macOS: SSH command (block on exit)
    │
    ├── App exits
    │
    ├── Grace period (VM_SUSPEND_GRACE_PERIOD seconds)
    │
    └── Cleanup old saves → Auto-suspend (virsh save)
```

## Configuration

```bash
# ~/.config/nextraos/vm.conf
VM_AUTO_SUSPEND=true            # Enable/disable auto-suspend
VM_SUSPEND_GRACE_PERIOD=30      # Seconds to wait after app exit
VM_SUSPEND_ON_SYSTEM_SUSPEND=true  # Suspend VMs on systemctl suspend
VM_SAVE_MAX_AGE_DAYS=7          # Auto-delete save files older than this
VM_SNAPSHOT_MAX_COUNT=10        # Max snapshots per VM (auto-rotate)
```

## Scope

- **Auto-suspend applies to**: apps launched via `nextraos-vm execute`
- **Auto-suspend does NOT apply to**: apps launched via SPICE
  (manual desktop interaction)
- `--no-auto-suspend` flag disables auto-suspend for a single
  execution

## Agent Ready Detection

Fixed `sleep` delays are replaced with active polling:

- **Windows VM**: Poll `guest-sync` via `qemu-guest-agent`
- **macOS VM**: Poll SSH connection (`ssh -o ConnectTimeout=1`)
- Default timeout: 120 seconds
- Configurable via `VM_READY_TIMEOUT` in vm.conf

---

# Memory Management

## Balloon Driver

Both Windows and macOS VMs use the virtio balloon driver for
dynamic memory adjustment.

```bash
# Adjust VM memory at runtime (requires balloon driver in guest)
nextraos-vm setmem windows 4096   # Set to 4GB
nextraos-vm setmem macos 8192     # Set to 8GB
```

The balloon driver allows the host to reclaim unused memory from
VM guests, improving overall system memory utilization.

## Hugepages (Optional)

For VMs with 4GB+ RAM, hugepages can reduce TLB misses and improve
memory access performance.

```bash
# Enable in ~/.config/nextraos/vm.conf
VM_HUGEPAGES=true
```

When enabled:

- 2MB hugepages are allocated before VM start
- Requires sufficient free pages on the host
- May require root or sysctl configuration
- Not enabled by default (adds complexity)

## Configuration

```bash
# ~/.config/nextraos/vm.conf
VM_HUGEPAGES=false              # Enable hugepages (default: false)
VM_AUTO_SUSPEND=true            # Auto-suspend on app exit
VM_SUSPEND_GRACE_PERIOD=30      # Seconds before auto-suspend
VM_SAVE_MAX_AGE_DAYS=7          # Auto-delete save files older than this
VM_SNAPSHOT_MAX_COUNT=10        # Max snapshots per VM (auto-rotate)
VM_READY_TIMEOUT=120            # Agent/SSH ready timeout
```
VM_READY_TIMEOUT=120         # Agent/SSH ready timeout
```

---

# Disk Configuration

## Windows VM Disk

| Property | Value |
|---|---|
| Format | qcow2 |
| Initial Size | 32GB |
| Max Size | Expandable (host-dependent) |
| Location | `~/.local/share/nextraos/vms/windows/disk.qcow2` |
| Bus | VirtIO |
| Cache | none |
| Discard | unmap (TRIM support) |

The Windows VM disk is created as a 32GB qcow2 image and expands
as needed. This is sufficient for a base Windows installation with
room for applications. Users can resize manually if needed:

```bash
# Resize Windows VM disk to 64GB
qemu-img resize ~/.local/share/nextraos/vms/windows/disk.qcow2 64G
```

## macOS VM Disk

| Property | Value |
|---|---|
| Format | qcow2 |
| Initial Size | 32GB |
| Max Size | Expandable (host-dependent) |
| Location | `~/.local/share/nextraos/vms/macos/macos.qcow2` |
| Bus | VirtIO |
| Cache | none |
| Discard | unmap |

Additionally, a 200MB OpenCore boot disk is created:

```
~/.local/share/nextraos/vms/macos/OpenCore.qcow2
```

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

## VM Management

- CPU pinning for dedicated VM cores
- Headless mode for execute-only workloads
- SPICE on-demand activation

## Windows

- Additional Windows VM optimizations
- Seamless window integration (if feasible)
- GPU passthrough (if feasible)

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

- Waydroid: https://github.com/waydroid/waydroid
- OpenCore: https://github.com/kholia/OSX-KVM
- SPICE: https://www.spice-space.org/
