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

# Wine / Bottles / Proton

Wine, Bottles, and Proton provide Windows compatibility layers.

Decision:

**Use Wine/Bottles/Proton as the primary Windows compatibility layer.**

The Docker-based VM approach (dockur/windows) was evaluated and rejected
because GPU passthrough is technically impossible in Docker containers.
Without GPU acceleration, Windows VMs are unsuitable for games, media,
and 3D applications.

Wine/Proton provides:
- Native GPU acceleration (via Linux GPU drivers)
- Low resource usage (2-4 GB RAM vs 8+ GB for VMs)
- Seamless window integration (native Linux windows)
- Good compatibility for Office, browsers, and games

Steam provides Proton automatically for games.

Implementation:

- `wine` from Debian contrib (with dependencies)
- `bottles` via Flatpak (GUI management)
- Steam/Proton for gaming
- Desktop integration via .desktop files
- MIME type registration for .exe, .msi

Limitations:

- Some Windows applications do not work under Wine
- DirectX 12 support is limited
- Anti-cheat software may not work
- Fallback: macOS VM for incompatible applications

---

# dockur/windows

dockur/windows provides a container-based Windows VM architecture
using KVM/QEMU underneath.

Decision:

**Deprecated. Not used in NextraOS.**

The Docker-based approach has fundamental limitations:

1. GPU passthrough is impossible in Docker containers
   - VFIO device assignment requires host kernel-level access
   - Docker's device abstraction prevents full PCI passthrough
   - Windows VirtIO GPU DOD driver lacks DirectX/OpenGL support

2. RDP-based display has unacceptable latency for:
   - Gaming
   - Video playback
   - 3D applications
   - Real-time interactions

3. Resource overhead is excessive:
   - Docker container layer adds overhead
   - QEMU inside Docker adds another layer
   - 8+ GB RAM required for acceptable performance

Alternative:

Use Wine/Bottles/Proton for Windows compatibility.
Use direct QEMU/KVM for macOS VM (experimental only).

---

# WinApps

WinApps provides seamless Windows application integration on Linux.

Decision:

**Deprecated. Not used in NextraOS.**

WinApps requires a Windows VM backend (dockur/windows) which has
fundamental GPU acceleration limitations. Without GPU passthrough,
WinApps cannot provide acceptable performance for:
- Games
- Media playback
- 3D applications

Additionally, WinApps depends on FreeRDP which has:
- Experimental Wayland support
- Unstable RemoteApp (RAIL) protocol
- Software-based rendering pipeline

Alternative:

Use Wine/Bottles/Proton for Windows compatibility with native
GPU acceleration.

---

# macOS Virtualization

macOS virtualization uses direct QEMU/KVM with OpenCore bootloader.

Decision:

**Use direct QEMU/KVM with OpenCore (not Docker).**

The Docker-based approach (dockur/macos) was evaluated and rejected
in favor of direct QEMU/KVM for the following reasons:

1. GPU passthrough requires direct host access
2. Docker adds unnecessary overhead
3. Direct QEMU/KVM provides better control
4. systemd integration is simpler without Docker

Implementation:

- QEMU/KVM with OpenCore bootloader
- SPICE protocol for display
- systemd user services for VM management
- Automated Recovery DMG download from Apple

Desktop Integration Limitations:

- macOS has no RemoteApp equivalent protocol
- **Full desktop access only** via SPICE
- Individual window forwarding is impossible
- Clipboard sharing via spice-vdagent
- Audio forwarding via SPICE

SPICE Integration:

- Use SPICE protocol for better integration than VNC
- spice-vdagent for clipboard sharing
- Dynamic resolution adjustment
- Audio forwarding
- Package: spice-gtk

OpenCore:

- Bootloader for non-Apple hardware
- SMBIOS identity spoofing
- VM detection hiding (VMHide.kext)
- Reference: https://github.com/kholia/OSX-KVM

AVX2:

- Required for macOS Ventura (13) and later
- Supported since Intel Haswell (4th gen, 2013)
- Supported since AMD Zen (Ryzen 1000, 2017)
- Not a significant limitation for modern hardware

CPU Requirements:

- Intel: host passthrough with vendor=GenuineIntel
- AMD: Haswell-noTSX or Skylake-Client-v4 with specific flags
- Required flags: +avx2, +fma, +aes, +sse4.2, +popcnt, +bmi1, +bmi2
- vmx=off (hide nested virtualization)
- vmware-cpuid-freq=on (TSC frequency)

Legal:

- macOS EULA restricts virtualization to Apple hardware
- NextraOS must document this restriction as experimental
- No proprietary Apple software should be redistributed

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

Docker was evaluated as a container/VM management layer but is no
longer used for VM hosting.

Decision:

**Docker is not used for VM management.**

Previous architecture used Docker for:
- dockur/windows (Windows VM)
- dockur/macos (macOS VM)

This approach was rejected because:
- Docker's device abstraction prevents GPU passthrough
- VFIO device assignment requires direct host kernel access
- Docker adds unnecessary overhead for VM workloads
- systemd provides better integration for VM management

Docker may still be useful for:
- Development containers
- CI/CD pipelines
- Application sandboxing

But not for running full VMs with GPU passthrough.

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

# systemd VM Management

VM lifecycle is managed via systemd user services.

Decision:

Use systemd user services for VM management.

Benefits:

- Automatic startup on login
- Clean shutdown handling
- Status monitoring
- Dependency management
- Integration with KDE Plasma

Implementation:

- Service files in `~/.config/systemd/user/`
- nextraos-vm.target for grouped control
- nextraos-macos.service for macOS VM
- Custom ExecStartPre/ExecStop for setup/cleanup

Service Example:

    [Unit]
    Description=NextraOS macOS VM
    After=network-online.target
    
    [Service]
    Type=simple
    ExecStartPre=/usr/local/bin/nextraos-vm-prepare macos
    ExecStart=/usr/bin/qemu-system-x86_64 [QEMU_ARGS]
    ExecStop=/usr/local/bin/nextraos-vm-shutdown macos
    Restart=on-failure
    
    [Install]
    WantedBy=default.target

---

# SPICE Protocol

SPICE is the display protocol for macOS VMs.

Decision:

Use SPICE for macOS VM display.

Advantages over VNC:

- Clipboard sharing via spice-vdagent
- Audio forwarding
- Dynamic resolution adjustment
- Better security (TLS support)
- Lower latency

Packages Required:

- spice-gtk (client)
- spice-vdagent (guest agent)
- spice-webdavd (folder sharing)
- qemu-system-x86 (with SPICE support)

Implementation:

- SPICE server enabled in QEMU
- spice-vdagent in macOS guest
- Clipboard sharing configured
- Audio forwarding enabled

---

# OpenCore Bootloader

OpenCore enables macOS booting on non-Apple hardware.

Decision:

Use OpenCore for macOS VM booting.

Sources:

- kholia/OSX-KVM (OVMF + Recovery scripts)
- thenickdude/KVM-Opencore (OpenCore builds)
- LongQT-sea/OpenCore-ISO (pre-built ISO)

Features:

- SMBIOS identity spoofing
- VM detection hiding (VMHide.kext)
- UEFI boot support
- ACPI patches

Configuration:

- config.plist customization
- Serial number generation (macserial)
- Kext injection (Lilu, VirtualSMC, WhateverGreen)

---

# VM Suspend / Resume

VM suspend preserves the full VM state to disk and frees host RAM.

Decision:

**Use `virsh save` / `virsh restore` for both Windows and macOS VMs.**

Rationale:

- Both VMs will be managed via libvirt after Phase 1 unification
- `virsh save` writes the complete VM state (CPU, memory, device state)
  to a file and releases all host RAM
- `virsh restore` resumes from the saved state file
- This is the standard libvirt mechanism and works reliably

Implementation:

    nextraos-vm suspend <vm>     # virsh save
    nextraos-vm resume <vm>      # virsh restore (latest save file)

Save file location:

    ~/.local/share/nextraos/vms/<vm>/save/suspend-<timestamp>.sav

Considerations:

- SPICE connection drops during suspend; client must reconnect after
  resume
- Save files are approximately equal to VM RAM size
- Multiple save files may accumulate; cleanup policy needed
- Systemd integration: auto-suspend on `systemctl suspend` / hibernate

Alternatives considered:

- QEMU `savevm` / `loadvm`: Requires QEMU monitor access; less
  portable across VM management methods
- Live migration: Overkill for single-host desktop use
- Pause (`virsh suspend`): Does not free host RAM

---

# VM Snapshots

Snapshots capture VM state at a point in time for rollback.

Decision:

**Use `virsh snapshot-create-as` with qcow2 internal snapshots.**

Rationale:

- qcow2 internal snapshots are self-contained (single file)
- libvirt manages snapshot metadata automatically
- Works for both Windows and macOS VMs

Implementation:

    nextraos-vm snapshot <vm> [name]            # create
    nextraos-vm restore-snapshot <vm> [name]     # revert
    nextraos-vm list-snapshots <vm>              # list
    nextraos-vm delete-snapshot <vm> <name>      # delete

Snapshot storage:

    ~/.local/share/nextraos/vms/<vm>/snapshots/

Considerations:

- Internal snapshots consume disk space proportional to changed blocks
- Disk-only snapshots (`--disk-only`) are faster but less complete
- External snapshots require careful disk chain management
- Default to internal snapshots for simplicity
- Maximum snapshot count per VM: 10 (configurable)

---

# Auto-Suspend on Application Exit

When a user launches an application via `nextraos-vm execute`, the VM
should auto-suspend after the application exits and a configurable
grace period.

Decision:

**Track process exit via guest agent (Windows) or SSH exit code
(macOS), then auto-suspend after a configurable grace period.**

Rationale:

- VMs consume significant RAM and CPU even when idle
- Users typically launch one application at a time per VM
- Auto-suspend frees host resources automatically
- Grace period allows follow-up actions before suspend

Implementation:

    # ~/.config/nextraos/vm.conf
    VM_AUTO_SUSPEND=true
    VM_SUSPEND_GRACE_PERIOD=30

Flow:

    nextraos-vm execute <vm> <app>
        |
        +--> VM not running? Start it
        |
        +--> Wait for agent/SSH ready
        |
        +--> Execute app (track PID / block on SSH)
        |
        +--> App exits
        |
        +--> Grace period (configurable, default 30s)
        |
        +--> virsh save (suspend, free memory)

Windows VM (guest agent):

    virsh qemu-agent-command <vm> \
      '{"execute":"guest-exec","arguments":{"path":"cmd.exe","arg":["/c","APP"],"capture-output":true}}'

    # Poll guest-exec-status for exit detection
    virsh qemu-agent-command <vm> \
      '{"execute":"guest-exec-status","arguments":{"pid":PID}}'

macOS VM (SSH):

    ssh -p 2222 user@localhost "$APP"
    EXIT_CODE=$?
    # exit code available immediately

Scope:

- Auto-suspend applies only to apps launched via `nextraos-vm execute`
- Apps launched via SPICE (manual desktop interaction) are not tracked
- `--no-auto-suspend` flag disables auto-suspend for a single execution

Alternatives considered:

- Periodic idle polling: Less reliable, cannot distinguish "user
  idle" from "app running but idle"
- D-Bus signals from guest: Requires guest-side agent installation;
  not available for macOS
- User notification only: Less automated; user must manually suspend

---

# Auto-Start and Agent Ready Detection

`nextraos-vm execute` should automatically start a VM if it is not
running, and wait for the guest to be ready before executing.

Decision:

**Replace fixed `sleep` delays with active readiness polling.**

Rationale:

- Fixed sleep (30s or 60s) wastes time on fast hardware and fails
  on slow hardware
- Active polling ensures the agent/SSH is actually ready
- Better user experience: no unnecessary waiting

Implementation:

Windows VM (guest agent polling):

    wait_for_agent_ready() {
        TIMEOUT=120; ELAPSED=0
        while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
            virsh qemu-agent-command <vm> \
              '{"execute":"guest-sync","arguments":{"id":1}}' \
              >/dev/null 2>&1 && return 0
            sleep 1; ELAPSED=$((ELAPSED + 1))
        done
        return 1
    }

macOS VM (SSH polling):

    wait_for_ssh_ready() {
        TIMEOUT=120; ELAPSED=0
        while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
            ssh -p 2222 -o ConnectTimeout=1 -o BatchMode=yes \
              user@localhost true 2>/dev/null && return 0
            sleep 1; ELAPSED=$((ELAPSED + 1))
        done
        return 1
    }

Timeout:

- Default: 120 seconds
- Configurable via `~/.config/nextraos/vm.conf`
- Warning emitted if timeout reached without readiness

---

# CPU Pinning and I/O Optimization

VM performance can be improved by pinning vCPUs to specific host
cores and optimizing disk I/O.

Decision:

**Use CPU pinning via libvirt cputune and virtio-scsi with
cache=none for I/O.**

CPU Pinning:

- Dedicate specific host cores to VM execution
- Reserve cores 0-1 (or 0-3 on high-core systems) for host
  responsiveness
- Assign remaining cores to VM via `<cputune><vcpupin>`
- Prevents VM from starving host processes

I/O Optimization:

- Use virtio-scsi controller for better throughput
- `cache=none`: Bypass host page cache; guest manages caching
- `discard=unmap`: Enable TRIM for qcow2 thin provisioning
- `aio=io_uring`: Async I/O on Linux 5.1+ (if available)

Implementation:

    virt-install \
        --disk ...,bus=virtio,cache=none,discard=unmap \
        --xml "<cputune><vcpupin vcpu='0' cpuset='2'/></cputune>" \
        ...

Alternatives considered:

- CPU shares (`cpu_shares`): Proportional, not exclusive; less
  predictable
- cgroup v2 cpu.max: More complex; libvirt cputune is sufficient
- NUMA pinning: Overkill for typical desktop VMs

---

# Memory Optimization (Balloon / Hugepages)

VM memory can be dynamically managed and optimized.

Decision:

**Use virtio balloon driver for dynamic memory adjustment and
optionally enable hugepages for large VMs.**

Balloon Driver:

- virtio-memballoon allows runtime memory adjustment
- Host can reclaim memory from idle VM guests
- Reduces memory pressure when VMs are running but underutilized

Implementation:

    virt-install --memballoon model=virtio ...

    # Runtime adjustment
    virsh setmem <vm> 2048 --config   # shrink
    virsh setmem <vm> 8192 --config   # expand

Hugepages (optional, for VMs with 4GB+ RAM):

- 2MB hugepages reduce TLB misses
- Requires host kernel configuration
- Not enabled by default (adds complexity)

Implementation:

    # Host: allocate hugepages
    echo 2048 > /proc/sys/vm/nr_hugepages

    # libvirt XML
    <memoryBacking>
      <hugepages>
        <page size='2048' unit='KiB'/>
      </hugepages>
    </memoryBacking>

Alternatives considered:

- KSM (Kernel Same-page Merging): Deduplicates memory pages across
  VMs; security concern with cross-VM data leakage
- Memory hotplug: Not supported by all guest OS configurations
- Swap: Last resort; severely degrades VM performance

---

# Display Optimization (Headless / SPICE on-demand)

VM display resources can be reduced when only executing commands.

Decision:

**Support headless mode for `nextraos-vm execute` and on-demand
SPICE activation.**

Rationale:

- `execute` use case does not require a display
- SPICE server consumes CPU and memory even when no client connects
- Headless mode reduces resource usage for batch/scripted execution

Implementation:

    # Headless execute
    nextraos-vm execute --headless windows "C:\app.exe"
    # -> virt-install --graphics none

    # SPICE on-demand (future)
    nextraos-vm display on <vm>   # enable SPICE
    nextraos-vm display off <vm>  # disable SPICE

Graphics options:

| Mode | Use Case | Resource |
|---|---|---|
| SPICE (default) | Interactive desktop use | Medium |
| VNC | Legacy clients | Low |
| Headless | execute-only, batch operations | Minimal |

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