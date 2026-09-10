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

# Reporting

Security-sensitive behavior should be documented in:

- architecture documentation
- user documentation
- installer warnings
