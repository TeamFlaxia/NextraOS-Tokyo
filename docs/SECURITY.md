# NextraOS Security Model

## Principle

NextraOS combines multiple execution environments.

This increases the attack surface.

Security must therefore be designed around isolation.

---

# Trust Boundaries

The following should be treated as separate trust domains:

- host Linux
- native applications
- Flatpak applications
- Android environment
- Windows VM
- macOS VM
- containers

---

# Filesystem

Do not expose the complete host filesystem to compatibility
environments by default.

Prefer:

- explicit shared directories
- user approval
- read-only mounts where possible

Sensitive directories must never be shared automatically.

Examples:

- `.ssh`
- browser profiles
- password stores
- credential files
- system configuration

---

# Network

VMs and containers should use isolated networking where practical.

Avoid unnecessary inbound ports.

---

# Devices

USB and GPU passthrough must require explicit configuration.

Do not automatically expose arbitrary host devices.

---

# Executables

Untrusted `.exe`, `.apk`, and other application files must not be
automatically granted unrestricted host access.

---

# Updates

Compatibility runtimes must have a clear update mechanism.

Do not modify upstream software silently.

---

# Desktop session and portals

Niri and Noctalia are trusted host-session components. A Wayland client in the same session may have broad access to compositor IPC, input, screen and clipboard depending on enabled protocols. Use reviewed portals/sandboxing for untrusted applications; do not treat Wayland alone as a security boundary. Keep shell plugins disabled by default or reviewed and pinned; do not allow automatic plugin updates in a release configuration.

## libvirt and Waydroid

A writable system-mode libvirt UNIX socket can provide root-equivalent control of the host. Keep remote libvirt listeners disabled, limit group membership, and use the Debian socket-activation path only for users who selected VM support. Guest creation and start must be explicit. Waydroid is a privileged container integration: binder/device access, host IPC, filesystem mounts, network and clipboard sharing must be documented and minimized. Initialize/download Android images only on explicit user action.

---

# Reporting

Security-sensitive behavior should be documented in:

- architecture documentation
- user documentation
- installer warnings
