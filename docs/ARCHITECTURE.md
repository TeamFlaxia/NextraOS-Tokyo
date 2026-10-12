# NextraOS Tokyo Architecture

## 1. Direction

NextraOS Tokyo targets a persistent Debian 13 (Trixie), AMD64 system. The host should remain a full Debian/glibc environment with systemd and APT, while the desktop and guest runtimes are modular and activated only when needed.

```text
Hardware
  └─ Linux kernel: DRM/KMS, KVM, binder, namespaces, cgroups
      └─ Debian minimal userland: systemd, D-Bus, udev, APT, NetworkManager
          └─ Wayland session: Niri compositor + Noctalia v5 shell
              ├─ Portals, PipeWire/WirePlumber, session authentication
              ├─ Native Linux applications
              ├─ Waydroid (Android container, on demand)
              └─ QEMU/KVM + libvirt (VMs, on demand)
```

Noctalia is the desktop shell, not a compositor, greeter, file manager, or replacement for portals. Niri is the compositor, not a complete desktop environment. Each required session service must be selected and tested explicitly.

The default package list still builds the historical KDE prototype; the Tokyo desktop remains a reversible test profile. A Trixie Niri + Noctalia ISO boots in QEMU, and a Weston-headless/llvmpipe render run produced a Niri `Virtual-1` output, Noctalia layer surfaces, a mapped Foot window, and an in-guest screenshot. VT resume and greetd recovery after a compositor SIGKILL were also exercised. This is smoke-profile evidence, not full Stage 1 acceptance: portals, actual audio playback, shell shutdown, persistence and memory targets remain open. See [ADR 0004](adr/0004-niri-noctalia-desktop.md) and the [roadmap](ROADMAP.md).

## 2. Session responsibilities

- **Niri:** Wayland compositor, window management, compositor IPC, session environment.
- **Noctalia v5:** bar, launcher, notifications, shell surfaces and settings. Start it from Niri as documented upstream. Do not run a duplicate bar or notification daemon without need.
- **Login/session:** use a display-manager session or other explicitly locked-down session launcher. Do not fall back to a bare TTY shell on compositor crash.
- **Portals:** configure portal backends for file chooser and screencast use; test them independently. Niri upstream recommends GNOME portal support for PipeWire screencasting and GTK as a fallback. Portal providers are host-trusted components.
- **Audio/network:** PipeWire + WirePlumber and NetworkManager are core host services; confirm functional controls in the shell.
- **X11 compatibility:** add XWayland support (upstream recommends xwayland-satellite where appropriate) only after native session startup is proven.

## 3. Runtime lifecycle

### Waydroid

Waydroid is a privileged Android container integration using Linux namespaces, binder and system services. Its binder setup and first `waydroid init`/image download must not run during idle boot. Initialize it on explicit runtime start, keep app data under persistent system storage, and document host-device, filesystem, network, IPC, clipboard and display access. Waydroid is not expected to work in the live ISO unless separately proven.

The repository now models the custom init and binderfs units as dependencies of the Waydroid container rather than enabling them at the default target. This startup contract has static tests, but the container-start dependency, image download and stop/restart path still require an installed-system integration test.

### QEMU/KVM and libvirt

Use QEMU/KVM through libvirt, with local UNIX sockets and systemd activation. Enable the socket path only for systems that selected VM support; do not start guest VMs from a login/default target. A writable system-mode libvirt socket is effectively root-equivalent access, so group membership and polkit authorization must be deliberate. Do not enable remote TCP/TLS sockets without separately designed authentication.

VM disk images and Android data belong on persistent storage. Host filesystem shares and device passthrough must be user-selected and narrow by default. Guests use isolated/NAT networking unless the user opts into another mode.

## 4. Persistence and resources

This project targets a persistent installed system, not an automatically persistent live USB. Validate that user files, settings, installed packages, Waydroid data and VM disks survive reboot after installation.

Idle memory is measured as `MemTotal - MemAvailable` at 5, 30 and 60 minutes after cold boot. Record PSS, zram, swap, PSI, boot timing, profile and conditions alongside it. The under-1024-MiB requirement and 850-MiB development goal remain unverified. Do not tune by dropping caches, hiding swap or disabling security services.

## 5. Compatibility path

Preferred execution order:

1. Native Linux / APT
2. Flatpak
3. Android / Waydroid
4. Windows VM / QEMU-KVM
5. macOS virtualization (experimental, legally constrained)

A compatibility resolver is a future component. Do not implement one before the execution environments and their boundaries are reliable.

## 6. Security boundaries

Treat the compositor and shell as trusted session components. Wayland does not isolate clients from the host session: malicious Wayland clients can abuse compositor/portal interfaces and user-level D-Bus. Use portals, Flatpak or other reviewed sandboxing for untrusted applications. Keep plugins user-space, review their provenance, and disable automatic plugin updates in a release configuration.

Do not expose the complete host filesystem, credentials, browser profiles, SSH keys, devices, or host network to a guest by default. Document per integration: privileges, filesystem, network, devices, IPC, clipboard and display access.

## 7. Migration gates

Before replacing the KDE prototype package/session configuration, prove a pinned Niri package build on Debian Trixie and a Noctalia v5 install path; then build and boot in QEMU. Verify login/logout and compositor failure handling, portals, XWayland (if selected), audio, networking, installer operation and shutdown. Only then remove the old Plasma-specific overlays and claim the Tokyo target boots.
