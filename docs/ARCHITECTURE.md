# NextraOS Architecture

## 1. Overview

NextraOS consists of several layers.

    Hardware
        |
        v
    Linux Kernel
        |
        +----------------------+
        |                      |
        v                      v
    Native Linux          Virtualization
        |                      |
        |              +-------+-------+
        |              |               |
        v              v               v
    KDE Plasma       KVM/QEMU       Containers
        |              |               |
        |              |               +--> Waydroid
        |              |
        |              +--> Windows
        |              +--> macOS
        |
        v
    NextraOS Integration Layer
        |
        +--> Application Discovery
        +--> Compatibility Resolver
        +--> Software Center
        +--> Desktop Integration
        +--> Notifications
        +--> Filesystem Integration
        |
        v
    User

## 2. Execution Environments

### Native Linux

Primary environment.

Used for:

- system applications
- APT packages
- Flatpak applications

### Wine

Used for Windows applications that work through Wine.

### Proton

Used primarily for applications where Proton provides better
compatibility, especially games.

### Waydroid

Provides an Android environment inside Linux.

### Windows VM

Used when Wine/Proton cannot provide sufficient compatibility.

Possible implementation technologies include:

- QEMU
- KVM
- Docker
- Podman
- dockur/windows

### macOS VM

Experimental.

Possible technologies include:

- QEMU
- KVM
- dockur/macos

Legal and hardware limitations must be respected.

## 3. Compatibility Resolver

Future component:

    Nextra Compatibility Resolver

Input:

    application identifier
    executable type
    package type
    metadata
    compatibility database
    host capabilities

Output:

    execution environment

Example:

    foo.deb
        -> native

    foo.flatpakref
        -> Flatpak

    foo.apk
        -> Waydroid

    foo.exe
        -> Wine
        -> Proton
        -> Windows VM

    foo.app
        -> macOS VM
        -> unsupported

The resolver must be deterministic and explainable.

## 4. Desktop Integration

Applications should expose standard Linux desktop entries.

Where possible:

- `.desktop` files
- MIME associations
- application icons
- startup notifications
- taskbar integration
- window titles
- notifications

The user should see an application rather than a VM.

## 5. Filesystem Integration

Filesystem sharing should be conservative.

Default behavior should favor:

- user-selected folders
- read-only access when practical
- explicit permissions

Do not expose the entire host filesystem to guests by default.

## 6. Networking

The default architecture should minimize guest exposure.

Use:

- NAT
- isolated networking
- explicit port forwarding

when possible.

## 7. Resource Management

Virtual machines must have configurable:

- CPU
- RAM
- storage
- GPU
- USB devices
- networking

The system should avoid allocating all host resources by default.

## 8. Modularity

Heavy components should be optional.

For example:

    Base OS
        |
        +--> Linux
        |
        +--> Android support
        |
        +--> Windows compatibility
        |
        +--> Windows VM
        |
        +--> macOS experimental support

The user should not need every subsystem installed.

## 9. Failure Handling

If an application cannot run:

    compatibility resolver
        |
        +--> compatible
        |
        +--> fallback available
        |
        +--> unsupported

The UI should explain why.

Never silently fail.

## 10. Security Boundary

Treat compatibility environments as potentially unsafe.

A Windows executable should not automatically receive unrestricted
access to:

- the home directory
- host devices
- host network
- credentials
- SSH keys
- browser profiles

without explicit permission.

## 11. Performance Principle

Performance optimization should follow:

1. native execution
2. compatibility layer
3. hardware-accelerated VM
4. fallback VM

Do not sacrifice system stability for theoretical performance.

## 12. Distribution Architecture

The ISO should remain relatively small.

Large components should be downloaded during installation.

The installed system can then contain the selected runtime environments.