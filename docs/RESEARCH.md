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
- Windows VM disk: 32GB qcow2 (expandable)

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

Debian Trixie Backports Waydroid `1.6.3+ds-2~bpo13+1` ships a system `waydroid-container.service` with `BusName=id.waydro.Container` and `WantedBy=multi-user.target`. Debian's `dh_installsystemd` enables unit files by default. The live-build hook and Calamares post-install module disable only the boot link with `systemctl --root=... disable waydroid-container.service`, preserving explicit D-Bus/systemd activation even if the installer installs the package; first-start and upgrade behavior still need an installed-system test. References: <https://sources.debian.org/src/waydroid/1.6.3%2Bds-2%7Ebpo13%2B1/systemd/waydroid-container.service/> and <https://manpages.debian.org/trixie/debhelper/dh_installsystemd.1.en.html>.

---

# Wine / Bottles / Proton

Wine, Bottles, and Proton provide Windows compatibility layers.

Decision:

**Not used in NextraOS.**

Wine was evaluated but rejected for the following reasons:

1. Modern Windows applications (especially .NET 6+, UWP, Electron
   with GPU acceleration) often do not work under Wine
2. DRM-protected content and anti-cheat software are incompatible
3. Wine introduces heavy i386 dependencies (8+ packages, Vulkan i386)
4. General users should not need to troubleshoot Wine failures
5. .exe files should go directly to the Windows VM

Steam manages its own Proton installation and does not require
NextraOS to bundle it.

Users who want Wine or Bottles can install them separately via
Flatpak or APT.

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

Use direct QEMU/KVM for Windows and macOS VMs.

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

Use direct QEMU/KVM for Windows VM.

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

Historical KDE prototype QEMU notes (not current Niri validation):

- QEMU 10.0.8 and UEFI via OVMF were used in an earlier prototype.
- That older setup used a VNC display and user-mode networking with SSH port forward (2222).
- The old input limitation was specific to the KWin prototype; it is not evidence for Niri behavior.
- The current `tools/run-qemu` uses `virtio-vga-gl` with SDL GL and does not expose VNC/Spice. Keep the GL path when testing the Niri compositor; actual rendering still needs validation.

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

Docker was evaluated as a container/VM management layer and for
general-purpose use.

Decision:

**Docker is not installed in NextraOS.**

Docker was rejected because:

- Docker's device abstraction prevents GPU passthrough
- VFIO device assignment requires direct host kernel access
- Docker adds unnecessary overhead for VM workloads
- systemd provides better integration for VM management
- General users should not need Docker for normal desktop usage

Podman was also evaluated but not included for the same reasons.

Users who need Docker or Podman can install them separately.

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

# KDE Plasma prototype (historical)

The KDE Plasma configuration describes the earlier live-build prototype, not the NextraOS Tokyo target. See ADR 0004 for the deliberate move to Niri + Noctalia v5. Keep the old implementation until the replacement session has a successful QEMU boot and functional integration tests.

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

# systemd VM Management (Tokyo policy)

VM lifecycle may be managed via systemd user services, but guests must not start automatically on login. Start selected VMs on explicit user action and use local libvirt socket activation for daemon demand.

Decision:

Use systemd/libvirt integration for VM management, with on-demand startup and explicit host-resource boundaries.

Benefits:

- Guest processes consume resources only when requested
- Clean shutdown handling
- Status monitoring
- Dependency management
- Desktop-independent session integration

The earlier KDE prototype enabled `libvirtd.service` at boot. Current Tokyo configuration switches selected VM support to `libvirtd.socket`; QEMU/runtime behavior still requires testing.

Debian Trixie `libvirt-daemon` 11.3.0-3+deb13u3 includes `/usr/lib/systemd/system/libvirtd.socket` (package file list: <https://packages.debian.org/trixie/amd64/libvirt-daemon/filelist>). Upstream documents socket activation for both monolithic and modular daemons: <https://libvirt.org/daemons.html>.

The current hooks enable the local `libvirtd.socket` for selected VM support; that service activation and user authorization must be verified in a target install. Do not enable remote TCP/TLS sockets or a default-target VM service. Older service examples in this document describe prototype experiments and are not a current implementation contract.

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

# SynWin

SynWin enables running the same Windows installation on both
bare metal (dual-boot) and in a VM under Linux.

Reference:

https://www.dragonhawk.org/tech/synwin/

Decision:

**Investigate in Phase 5, implement in Phase 7 if viable.**

Key Concepts:

- Synthetic disk via Linux device mapper (dmsetup)
- Real partition mapping (ESP, MSR, Windows)
- Hardware spoofing for Windows license continuity
- Network bridging via TAP devices
- Single Windows installation shared between bare metal and VM

Architecture:

    Bare Metal Boot
        |
        +--> Windows boots directly on hardware (normal dual-boot)

    VM Boot (under Linux)
        |
        +--> synwin_prep creates synthetic disk
        |       |
        |       +--> Maps ESP, MSR, Windows partitions
        |       +--> Copies preamble (MBR+GPT)
        |       +--> Creates network bridge
        |
        +--> QEMU/KVM boots Windows from synthetic disk
        |
        +--> synwin_done cleans up after shutdown

Requirements:

- Microsoft Windows installed on bare metal (GPT/UEFI)
- Linux with KVM support
- QEMU virtual machine manager
- gdisk partitioning tool
- UEFI boot (not BIOS nor CSM)
- GPT-based partitioning (not MBR/BIOS)
- Single Windows partition
- Microsoft-recommended partition order (ESP, MSR, Windows)

Implementation:

    synwin_prep     # Run as root: create synthetic disk, network bridge
    synwin_run      # Run as user: start QEMU/KVM with Windows
    synwin_done     # Run as root: cleanup synthetic disk, network bridge

Limitations:

- No Secure Boot support in VM
- No TPM support in VM
- BitLocker with TPM keys fails (PIN/USB key may work)
- Fast Startup must be disabled in Windows
- VirtIO display drivers may need pre-installation on bare metal
- GPT/UEFI required (no MBR/BIOS support)
- Partition table backup (GPT tail) is not mapped (returns zeros)

Hardware Spoofing:

Windows uses hardware attributes for license activation/tracking.
SynWin spoofs these attributes to match bare metal:

- PC make, model, serial number
- Mainboard make, model, serial number
- Hard disk serial number

All obtainable via dmidecode(8) under Linux.

Network Identity:

Windows in VM needs separate network identity from Linux host:

- Distinct hostname
- Distinct IP address (DHCP reservation or static)
- Distinct MAC address (LAA recommended)

This prevents name/IP conflicts when both run simultaneously.

Integration with NextraOS:

Phase 5 (Investigation):

- Analyze SynWin source code
- Verify device mapper functionality
- Test hardware spoofing effectiveness
- Evaluate security implications
- Document findings in this file

Phase 7 (Implementation):

- Add `nextraos-vm detect-windows` command
- Add `nextraos-vm create-syndisk` command
- Add `nextraos-vm start windows --synwin` option
- Add `nextraos-vm done-syndisk` command
- Integrate with systemd services
- Add to desktop integration (MIME handlers, .desktop files)

Alternatives Considered:

- WinApps: Uses RDP/RemoteApp; requires separate Windows install
- WinBoat: Docker-based; has GPU passthrough limitations
- Wine/Bottles: Compatibility issues with many Windows apps
- Standalone qcow2: Requires separate Windows installation

---

# Niri + Noctalia v5 (Tokyo target)

Research reviewed 2026-10-11 against upstream documentation and Debian/Noctalia package metadata. Niri and Noctalia are included only in the disposable live-build smoke profile; the default KDE image is not the Tokyo target.

## Niri

- Upstream: <https://github.com/niri-wm/niri>
- Current inspected stable release: v26.04; <https://github.com/niri-wm/niri/releases/tag/v26.04>. The annotated tag points to commit `8ed0da44d974c32c6877d2f4630c314da0717ecb`; GitHub reports the tag unsigned, so pin and verify the full commit rather than trusting the movable tag name.
- License: GPL-3.0-or-later (release Cargo manifest).
- Architecture/status: Rust Wayland compositor; upstream describes it as stable for daily use but not a complete desktop. It needs a shell and separate session components.
- Debian status: no Niri compositor package in Debian Trixie and no upstream Debian APT archive found. Exact-suite package search: <https://packages.debian.org/search?suite=trixie&searchon=names&keywords=niri>.
- Build: v26.04 requires Rust >=1.85; Trixie's rustc is 1.85.1. The release artifact is a vendor archive, not a binary/deb: `niri-26.04-vendored-dependencies.tar.xz`, SHA-256 `407c525cd78710e72455c48741756857ca47dc32910a42f82cd40992a34beed6`. Upstream's workflow archives `vendor/` only; its generated `.cargo/config.toml` is not included, so an offline package build must preserve and test the Cargo source-replacement config. Use default features and do not build with `--all-features`. The source's version reporter honors `NIRI_BUILD_COMMIT`; the package recipe sets it to the pinned commit.
- Build dependencies from the v26.04 workflow include GCC/Clang, pkg-config, and Trixie development packages for udev, GBM, xkbcommon, EGL, Wayland, libinput, D-Bus, systemd, libseat, PipeWire, Pango and libdisplay-info. Building the full workspace also uses libadwaita; the project build of only `-p niri` succeeded in Trixie without `libadwaita-1-dev`.
- Decision: create a project-owned Debian package from the pinned source; include Debian-generated runtime dependencies and explicit `libwayland-server0`. Upstream Cargo Debian metadata adds Alacritty and Fuzzel, which do not match the Noctalia target. The staged recipe in `packages/nextraos-niri/` regenerates Cargo vendoring from the pinned `Cargo.lock`, then builds offline. A fresh Trixie/AMD64 container build succeeded and all 195 Niri unit tests passed; installing the generated package in a second fresh Trixie container resolved runtime dependencies and `niri --version` reported the pinned commit. It is included only in the disposable Niri smoke profile, not the default image. Third-party crate license notice harvesting and systemd-user unit validation still need review. Do not install a moving branch, mix testing/unstable, or use an unreviewed community package as the base.
- Integration assets: install `niri-session`, `niri.desktop`, `niri.service`, `niri-shutdown.target` and `niri-portals.conf` with the compositor. The session script imports environment into systemd user/D-Bus and starts the compositor service; do not replace it with a raw compositor `Exec`. The upstream default config starts Waybar and binds Alacritty, Fuzzel and Swaylock, so ship and test an NextraOS config that starts Noctalia and uses installed commands. The pinned portal config prefers `gnome;gtk`, routes Access/Notification to GTK, and Secret to GNOME Keyring. Niri's screencasting documentation explicitly requires a D-Bus session, PipeWire, `xdg-desktop-portal-gnome`, and a `niri-session` launch; verify backend behavior and fallback in a real session. Niri upstream recommends `xwayland-satellite` for X11 apps, but Debian Trixie has no such package; do not claim X11 compatibility until a separate package/alternative is reviewed and tested.
- Security: Niri's security model treats same-session Wayland clients as mutually trusted; untrusted apps need sandboxing, filtered portals and restricted IPC. See <https://niri-wm.github.io/niri/Security-Model.html>.

References:

- <https://niri-wm.github.io/niri/Getting-Started.html>
- <https://niri-wm.github.io/niri/Packaging-niri.html>
- <https://github.com/niri-wm/niri/blob/v26.04/.github/workflows/release.yml>
- <https://doc.rust-lang.org/cargo/commands/cargo-vendor.html>
- <https://raw.githubusercontent.com/niri-wm/niri/8ed0da44d974c32c6877d2f4630c314da0717ecb/resources/niri-session>
- <https://raw.githubusercontent.com/niri-wm/niri/8ed0da44d974c32c6877d2f4630c314da0717ecb/resources/niri.service>
- <https://niri-wm.github.io/niri/Security-Model.html>
- <https://github.com/niri-wm/niri/blob/8ed0da44d974c32c6877d2f4630c314da0717ecb/docs/wiki/Xwayland.md>
- <https://packages.debian.org/search?searchon=names&keywords=xwayland-satellite>

## Noctalia v5

- Upstream: <https://github.com/noctalia-dev/noctalia>
- Inspected release: v5.2.1, <https://github.com/noctalia-dev/noctalia/releases/tag/v5.2.1>.
- License: MIT; preserve all upstream and vendored third-party notices.
- Architecture: native C++23 Wayland shell. It is not a compositor, greeter, file manager or screen-casting/drive-mount replacement. Do not use Quickshell-based Noctalia v4 recipes; v5 is a fresh install and does not migrate v4 settings.
- Debian status: the Noctalia documentation lists a Trixie APT repository, but the repository is community-maintained and is not part of Debian's archive. The current `amd64` package is `noctalia` `5.2.1-1+deb13u1`, SHA-256 `63a0aa02fab9c83edaf0c3a063bb3c3079c7ea3673fa37c8ff18d47c5cae02f7`; the live `Packages` index matched both. The package has a 27,219 KiB installed size and depends on `pipewire`, `git`, and polkit-agent libraries among other runtime libraries; it recommends `upower`, `wtype`, `ddcutil`, and `sound-theme-freedesktop`. A clean `--no-install-recommends` smoke install selected 150 new packages including transitive runtime libraries; this is package count, not a count of active daemons or resident memory.
- Repository trust: the Trixie `.sources` file is scoped with `Signed-By`. The key fingerprint `C2A7 E07F B3D7 46BD F2A2 45CD 683B 67D7 BC99 A9B7` (expiry 2027-06-01) was checked independently with GPG. A clean Trixie container accepted the signed APT index, downloaded the pinned package, and matched its SHA-256. This authenticates to an individual community packager's key; it is not Debian endorsement or Debian security support.
- Install/config smoke test: installing the exact package version in a disposable Trixie/AMD64 container with `--no-install-recommends` resolved dependencies; `noctalia --version`, `noctalia --help`, and `noctalia config validate` succeeded against the project TOML profile. The profile selects Secret Service, enables the Noctalia polkit agent and first-run wizard, disables screen-time tracking, telemetry/external-IP lookups, and launcher exchange-rate lookups. This did not start the GUI or connect to a Secret Service provider. Review recommends and the full app lifecycle before selecting components for the image.
- Decision: prefer mirroring the pinned package, source and build metadata into a NextraOS-controlled signed repository for repeatable builds. If temporarily using the community archive, pin the exact version and hash, verify the signing-key fingerprint, and define update/key-rotation policy. The community archive is configured only for the disposable smoke build chroot, not the default or release image.
- Integration: upstream Niri guidance starts Noctalia from `spawn-at-startup`; documented IPC binds include `noctalia msg panel-toggle launcher` and `noctalia msg panel-toggle control-center`. The smoke profile starts a `noctalia.service` user unit from Niri instead of launching the shell as an unmanaged child. `BindsTo=niri.service`, `PartOf=niri.service` and `TimeoutStopSec=5s` bound a stale Noctalia process after compositor failure. On a fresh ISO, the unit started with the active Wayland environment and provided layer surfaces; after Niri SIGKILL it reached `failed/timeout` at five seconds and no process remained. Relogin started Niri and Noctalia again. The current prototype ships no plugins. A release configuration must still disable automatic plugin updates and only include reviewed plugins. Shell plugins and shell session components are trusted user-space code.
- Session dependency smoke: a disposable Trixie container installed the pinned Niri and Noctalia packages with `sddm`, `foot`, `thunar`, NetworkManager, PipeWire/WirePlumber, `xdg-desktop-portal-gnome` + GTK, and `polkitd`; package versions and the Niri KDL parser check passed. A later isolated Noctalia test validated the current TOML profile. Neither test started a display or user session. The candidate set also installed Nautilus and `xserver-xorg-video-all`, exposing a duplicate file-manager choice and a heavier-than-expected greeter path.
- Secret storage and login: the project TOML profile sets `[storage].key_source = "secret-service"`; pinned Niri's portal config routes the Secret interface to `gnome-keyring`. A Trixie/AMD64 APT simulation with GNOME Keyring and its PAM module selected 485 new-package actions with SDDM versus 420 with greetd + tuigreet for the same candidate desktop dependencies. These counts are not RAM or live-session results. The corrected clean-boot ISO now accepts the `user`/`live` login and starts a `Type=wayland`, `Desktop=niri` session with Noctalia, PipeWire and WirePlumber processes; NetworkManager reports the emulated NIC connected and `wpctl status` lists virtual audio sink/source endpoints. A D-Bus Peer.Ping activated `xdg-desktop-portal`; this does not verify portal workflows, secret unlock, actual playback or network requests. The non-GL GTK QEMU window remained black; later headless Weston/llvmpipe GL testing produced an active guest output and a Niri screenshot, so this limitation is specific to the non-GL path.
- Full profile resolution: the initial `desktop.list.chroot`, local Niri `.deb`, signed Noctalia source and origin/version pins resolved 451 `Inst` actions in a fresh Trixie/AMD64 `apt-get -s --no-install-recommends` run before explicit `ca-certificates`, `user-setup`, and greeter provisioning were added. The subsequent live-build completed with those additions; rerun a standalone simulation for an exact current count. This is package resolver closure only; it is not an installed-RAM or runtime measurement.
- Account provisioning: Debian Trixie's live-config 11.0.5 `0030-user-setup` component exits when the `user-setup` package is absent and otherwise creates the configured `username` (its documented default password is `live`). Debian's greetd postinst creates `_greetd` for the daemon, not a `greeter` account for the configured tuigreet process; the test profile must provision that separate unprivileged account. See the [live-config component source](https://sources.debian.org/src/live-config/11.0.5/components/0030-user-setup/).
- Live boot diagnostics: the first UEFI ISO booted under QEMU/TCG but its live-config automatic tty login failed. `noautologin` removed that race and greetd's VT was moved to 7 to match Debian's unit. The next ISO still failed: the journal showed greetd restarting because its configured `greeter` account did not exist, and the live user `user` was absent because the profile omitted `user-setup`. The corrected profile adds `user-setup` plus a chroot hook creating the separate unprivileged greeter account; the rebuilt ISO clean-boots to tuigreet and accepts `user`/`live`. On this host, default SDL GL fails with `X_GLXCreateNewContext`; GTK GL-on fails with `EGL_BAD_ACCESS` and reports that GTK OpenGL is unsupported. GTK `gl=off` and legacy Bochs VGA show the greeter but leave the post-login desktop black. A timer with tight accuracy confirmed `niri msg --json outputs` returns `{}` while logind reports the Wayland session `Active=yes` on tty7. Restarting Niri while tty7 is active opens `/dev/dri/card0`, but renderer setup reports `kmsro: driver missing`, skips software EGL, and has no allocator. The host has neither `/dev/dri` nor `/dev/kvm`; minimal `virtio-vga-gl` probes with `egl-headless` and SPICE-app GL both exit with `no drm render node available`; `-display none` rejects `virtio-vga-gl` because that backend has no OpenGL support. These probes confirm the direct QEMU EGL/SPICE and host GLX frontends are unavailable; non-GL runs are not a valid Niri rendering test. Surfaceless Mesa EGL does work with llvmpipe: Weston 14 `--backend=headless --renderer=gl` plus QEMU SDL over `SDL_VIDEODRIVER=wayland`, `LIBGL_ALWAYS_SOFTWARE=1` and guest `virtio-vga-gl` under TCG successfully rendered the desktop without a physical GPU. Niri used guest `/dev/dri/renderD128` and `/dev/dri/card0`, reported `Virtual-1` at 1280×800, and Noctalia created wallpaper/bar/panel layer surfaces. `niri msg action screenshot-screen` captured both the launcher and a mapped Foot window (see [the screenshot](assets/niri-weston-launcher.png)). QMP `screendump` still returns `no surface` for GL scanout. This validates headless software-rendered output, not native-GPU performance.
- DRM/libseat diagnosis: session 3 and Niri's systemd user service both carried `XDG_SESSION_ID=3`, `XDG_SEAT=seat0`, and `XDG_VTNR=7`; `graphical.target`, greetd and the active login session were healthy. Niri's pinned [TTY device-add path](https://github.com/niri-wm/niri/blob/8ed0da44d974c32c6877d2f4630c314da0717ecb/src/backend/tty.rs#L740-L816) opens the primary node through Smithay/libseat before initializing DRM/GBM/EGL. The earlier non-GL run returned EAGAIN on VT resume even though a separate user-level O_RDWR nonblocking open of `/dev/dri/card0` succeeded; forcing `LIBSEAT_BACKEND=logind` or `seatd` did not resolve it, so that path's root cause remains unproven. In the headless Weston/virgl GL run, Ctrl+Alt+F2 then Ctrl+Alt+F7 resumed Niri, retained `Virtual-1`, and did not log EAGAIN. Smithay maps libseat's device-open errno directly ([pinned session backend](https://github.com/Smithay/smithay/blob/ff5fa7df392cecfba049ffed55cdaa4e98a8e7ef/src/backend/session/libseat.rs)); systemd documents asynchronous pause/resume semantics for login1 device FDs ([Session objects](https://www.freedesktop.org/software/systemd/man/latest/org.freedesktop.login1.html#Session%20Objects)). Keep the earlier failure distinct from the tested virgl path. QEMU documents that its 2D VirtIO GPU path uses guest software rendering, whereas `virtio-vga-gl` provides the GL path ([VirtIO GPU](https://www.qemu.org/docs/master/system/devices/virtio/virtio-gpu.html)); pinned Niri skips software EGL, but host llvmpipe through Weston GL can still supply QEMU's virtual GL device.

References:

- <https://docs.noctalia.dev/noctalia/getting-started/installation/>
- <https://docs.noctalia.dev/noctalia/compositor-settings/niri/>
- <https://docs.noctalia.dev/noctalia/getting-started/running-the-shell/>
- <https://docs.noctalia.dev/noctalia/configuration/>
- <https://docs.noctalia.dev/noctalia/configuration/secret-service/>
- <https://niri-wm.github.io/niri/Screencasting.html>
- <https://packages.debian.org/trixie/greetd>
- <https://packages.debian.org/trixie/tuigreet>
- <https://manpages.debian.org/trixie/live-config-doc/live-config.7.en.html>
- <https://raw.githubusercontent.com/niri-wm/niri/8ed0da44d974c32c6877d2f4630c314da0717ecb/resources/niri-portals.conf>
- <https://pkg.noctalia.dev/deb/noctalia-trixie.sources>
- <https://pkg.noctalia.dev/deb/trixie/InRelease>
- <https://pkg.noctalia.dev/deb/nickh-archive-keyring.gpg>

Neither Niri nor Noctalia upstream guarantees the Tokyo <1024 MiB idle-memory target. Measure the composed, pinned system using [the benchmark procedure](MEMORY-BENCHMARK.md).

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