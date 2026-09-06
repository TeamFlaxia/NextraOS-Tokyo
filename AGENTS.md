# AGENTS.md

## Project

NextraOS

Tagline:

> One Desktop. Every App.

NextraOS is an experimental Debian-based desktop Linux distribution
designed around a single coherent Wayland desktop experience capable
of launching applications from multiple operating-system ecosystems.

The project is intentionally experimental.

The primary objective is not to replace or reimplement mature
upstream projects. The objective is to integrate existing open-source
technologies into a coherent operating system experience.

---

# 1. Mission

NextraOS should provide:

- Native Linux applications
- Android applications
- Windows applications
- Experimental macOS application support
- A unified application launcher
- A unified desktop/taskbar experience
- Unified notifications where technically possible
- Shared filesystem integration where safe
- Shared clipboard integration where safe
- Shared application discovery
- A network-first software installation experience

The user should not need to understand which compatibility layer
or virtualization technology is being used.

For example:

    Linux application
        -> native Linux

    Android application
        -> Waydroid

    Windows application
        -> Wine / Bottles
        -> Proton where appropriate
        -> Windows VM fallback

    macOS application
        -> macOS virtualization
        -> experimental

The implementation details should be hidden whenever practical.

---

# 2. Core Philosophy

## 2.1 One Desktop

All supported applications should appear to the user as normal
desktop applications.

The user should not need to manually launch:

- Wine
- Bottles
- Waydroid
- QEMU
- Docker
- VM management software

for normal application usage.

These are implementation technologies, not primary user-facing
concepts.

---

## 2.2 Use Existing Open Source Software

Do not reinvent mature technologies.

Prefer integration over reimplementation.

Examples:

- Debian
- live-build
- KDE Plasma
- Wayland
- PipeWire
- Wine
- Bottles
- Proton
- Waydroid
- QEMU
- KVM
- Docker or Podman
- dockur/windows
- dockur/macos
- Flatpak
- APT

If an existing project already solves a problem reasonably well,
NextraOS should integrate it rather than implement a competing
replacement.

---

## 2.3 Verify Before Assuming

Do not make technical assumptions based on intuition.

Before concluding that something is impossible:

1. Find the upstream project.
2. Read its current documentation.
3. Inspect its repository when necessary.
4. Check current limitations.
5. Build a minimal proof of concept.
6. Record the result in `docs/RESEARCH.md`.

Unusual architectures are allowed.

Claims such as:

> "Docker cannot do that."

or:

> "Linux cannot run that."

must not be made without verification.

---

# 3. Base System

The initial target is:

- Debian Trixie
- AMD64
- KDE Plasma
- Wayland
- systemd
- PipeWire
- NetworkManager
- Network-first installation

The ISO should be intentionally small.

The ISO is primarily:

- a boot environment
- a hardware detection environment
- an installer environment
- a minimal live environment

Large compatibility runtimes should not automatically be embedded
into the ISO.

They should preferably be downloaded during installation.

---

# 4. Build Strategy

The first implementation target is a QEMU-runnable Live ISO.

The build system should preferably use Debian-native tooling,
especially `live-build`, rather than creating a custom distribution
build system unnecessarily.

The build must be reproducible as far as reasonably possible.

The repository should make it possible to:

1. configure the image
2. build the ISO
3. boot it in QEMU
4. run automated smoke tests
5. install NextraOS into a virtual disk
6. boot the installed system

---

# 5. Development Stages

Do not attempt to implement the complete NextraOS architecture
in one step.

Development must proceed incrementally.

## Stage 0 — Research

Research:

- Debian Trixie
- live-build
- KDE Plasma Wayland
- Wayland
- PipeWire
- APT
- Flatpak
- Wine
- Bottles
- Proton
- Waydroid
- QEMU
- KVM
- Docker
- Podman
- dockur/windows
- dockur/macos
- desktop integration projects
- filesystem integration
- application discovery
- security boundaries
- licensing
- legal restrictions

Record findings.

---

## Stage 1 — Bootable ISO

Produce:

- Debian-based ISO
- UEFI boot
- AMD64
- KDE Plasma
- Wayland
- NetworkManager
- PipeWire
- terminal
- file manager
- settings
- Firefox

The ISO must boot successfully in QEMU.

---

## Stage 2 — Installer

Implement the NextraOS installer.

The installer should be network-first.

The installer should:

1. detect hardware
2. detect network connectivity
3. collect user information
4. configure locale
5. configure keyboard
6. configure timezone
7. allow ecosystem selection
8. allow starter applications
9. show hardware requirements
10. calculate required disk space
11. download selected components
12. install the system
13. configure the selected runtime environments
14. create desktop/application integration
15. reboot into the installed system

---

## Stage 3 — Native Linux Applications

Implement:

- APT
- Flatpak
- desktop application discovery
- Software Center integration
- application menu integration

Starter applications:

- Firefox
- GIMP
- VLC Media Player
- VSCodium

---

## Stage 4 — Windows Compatibility

Implement:

1. Wine
2. Bottles
3. Proton where appropriate
4. application metadata
5. executable detection
6. desktop integration
7. Windows VM fallback

The fallback should not be treated as an ordinary application
launcher.

It is a compatibility fallback.

---

## Stage 5 — Android

Integrate Waydroid.

The goal is:

- APK installation
- Android application discovery
- application menu integration
- Wayland/window integration
- clipboard integration where possible
- filesystem integration where safe
- notifications where possible

---

## Stage 6 — Windows VM

Investigate and integrate:

- QEMU
- KVM
- Docker/Podman
- dockur/windows
- WinApps
- WinBoat
- related projects

Do not fork these projects without a strong reason.

The VM should eventually expose Windows applications as closely as
possible to normal desktop applications.

---

## Stage 7 — macOS Experimental Support

Investigate:

- QEMU
- KVM
- dockur/macos
- hardware compatibility
- legal restrictions
- licensing
- Apple hardware requirements
- distribution restrictions

macOS support must remain explicitly experimental.

Do not present macOS compatibility as guaranteed.

Do not distribute proprietary Apple software or copyrighted system
images.

NextraOS should provide integration mechanisms only where legally
appropriate.

---

# 6. Hardware Profiles

NextraOS has three hardware levels.

## Limited Mode

Minimum target:

- AMD64-compatible CPU
- 2 GB RAM
- 32 GB storage

Expected experience:

> A constrained/basic desktop environment.

This is not expected to support the complete NextraOS ecosystem.

---

## Full-Feature Minimum

Target:

- AVX2-capable CPU for the full virtualization feature set
- Intel Haswell 4th generation or newer
- AMD Zen / Ryzen 1000 series or newer
- 8 GB RAM
- 128 GB storage
- hardware virtualization enabled

This represents the minimum practical target for the complete
feature set.

Important:

AVX2 is NOT a requirement for the basic NextraOS desktop.

It is a requirement for specific advanced virtualization scenarios,
especially experimental macOS virtualization.

---

## Recommended

Normal NextraOS recommendation:

- Intel Core 7th generation or newer
- AMD Ryzen 5th generation or newer
- 16 GB RAM or more
- 512 GB SSD or more
- NVMe preferred
- hardware virtualization enabled

This is the recommended development and user environment.

The goal is:

> A PC from around 2020 or newer should provide a comfortable
> NextraOS experience.

---

# 7. Resource Policy

Do not describe 8 GB RAM as "comfortable".

8 GB is the full-feature minimum target.

16 GB is the recommended baseline.

32 GB or more is preferred for users who intend to run:

- Windows VMs
- macOS VMs
- Android
- development tools
- browsers
- containers

simultaneously.

NextraOS must not optimize for benchmark numbers at the expense
of actual multitasking usability.

---

# 8. Installer UX

The installer should follow this conceptual flow.

## Welcome

    NextraOS Installer

    Welcome to NextraOS!
    Let's install it!

    [Continue]

---

## User

    What's your name?

    [Username]
    [Password]
    [Confirm Password]

    [Continue]

---

## Language and Time

    Language
    [ English (United States) ]

    Keyboard
    [ US ]

    Timezone
    [ Asia/Tokyo ]

    [Continue]

---

## Ecosystem Selection

    NextraOS can run anything you want.
    What type of apps do you want?

    [x] Linux apps
        [x] APT packages
        [ ] Flatpak applications

    [x] Android apps
        [x] Waydroid

    [x] Windows apps
        [x] Wine / Bottles
        [x] Proton
        [ ] Windows VM fallback [Experimental]

    [ ] macOS apps
        [ ] macOS virtualization [Experimental]

    [ Requirements ]

    [Continue]

The UI should dynamically explain requirements based on selected
components.

---

## Starter Kit

    Starter Kit

    [x] Firefox
    [x] GIMP
    [x] VLC Media Player
    [x] VSCodium

    Debian Trixie

    [x] main
    [x] contrib
    [x] non-free

    KDE Plasma + Wayland

    [Note: These options are normally safe to leave unchanged.]

---

## Installation Target

    Where do you want to install NextraOS?

    [ ] Disk A
        XXX GB available
        Recommended

    [ ] Disk B
        XX GB available
        Not enough space

    [Install]

The installer must calculate actual requirements instead of relying
on a hardcoded 128 GB requirement.

VM images can consume significant additional disk space.

---

# 9. Application Menu

The initial application menu should conceptually contain:

    Internet
    └── Firefox

    Graphics
    └── GIMP

    Multimedia
    └── VLC Media Player

    Development
    └── VSCodium

    System
    ├── File Manager
    ├── Terminal
    ├── Settings
    └── Software Center

    Windows Apps
    ├── Wine / Bottles
    ├── Proton
    └── Windows VM

    Android Apps
    └── Waydroid

    Virtualization
    ├── Docker
    └── QEMU / KVM

The exact KDE menu implementation may change.

The user-facing organization matters more than the implementation.

---

# 10. Software Center

The Software Center is a core component of NextraOS.

It should eventually provide one interface for:

- Debian packages
- Flatpak applications
- Windows applications
- Android applications
- experimental macOS applications

The user should search for an application first.

The system should then determine how it can be executed.

Conceptually:

    application
        |
        v
    compatibility resolver
        |
        +--> native Linux
        |
        +--> Flatpak
        |
        +--> Wine
        |
        +--> Proton
        |
        +--> Waydroid
        |
        +--> Windows VM
        |
        +--> macOS VM
        |
        +--> unsupported

The compatibility resolver is a future major component.

It should not be implemented until the underlying execution
environments are reliable.

---

# 11. Compatibility Philosophy

The order of preference should be:

1. Native Linux
2. Flatpak
3. Wine
4. Proton
5. Waydroid
6. Windows VM
7. macOS virtualization

This ordering is not absolute.

The resolver should consider application-specific compatibility.

For example, a game may prefer Proton over ordinary Wine.

A business application may require a Windows VM.

An Android application should use Waydroid.

---

# 12. Security

Security is a first-class design requirement.

Never expose host resources unnecessarily.

VMs and compatibility layers must have explicit boundaries.

Avoid:

- unrestricted host filesystem access
- unnecessary privileged containers
- automatic execution of untrusted files
- automatic installation of arbitrary packages
- implicit network exposure
- credential sharing without user consent

For every integration, document:

- privileges
- filesystem access
- network access
- device access
- IPC
- clipboard access
- display access

---

# 13. Legal and Licensing

NextraOS must distinguish between:

- open-source software that can be redistributed
- proprietary software that cannot be redistributed
- software requiring user-provided installers/images
- software with trademark restrictions
- software requiring separate licensing

Do not bundle proprietary operating system images unless redistribution
is legally permitted.

Windows and macOS integration must not imply endorsement by Microsoft
or Apple.

macOS support must explicitly document applicable licensing and
hardware restrictions.

---

# 14. Research Requirements

Whenever evaluating an external project:

Record:

- project name
- upstream URL
- license
- current version/status
- supported architectures
- dependencies
- hardware requirements
- security model
- integration possibilities
- known limitations
- maintenance activity
- whether NextraOS should:
  - use it directly
  - wrap it
  - patch it
  - fork it
  - replace it

Prefer direct upstream integration.

---

# 15. Repository Structure

A preferred repository structure:

    .
    ├── AGENTS.md
    ├── README.md
    ├── LICENSE
    ├── docs/
    │   ├── ARCHITECTURE.md
    │   ├── COMPATIBILITY.md
    │   ├── DEVELOPMENT.md
    │   ├── HARDWARE.md
    │   ├── INSTALLER.md
    │   ├── RESEARCH.md
    │   ├── ROADMAP.md
    │   └── SECURITY.md
    ├── build/
    │   ├── live-build/
    │   └── scripts/
    ├── installer/
    ├── packages/
    ├── desktop/
    ├── integrations/
    │   ├── wine/
    │   ├── waydroid/
    │   ├── windows-vm/
    │   └── macos-vm/
    ├── software-center/
    ├── tests/
    ├── ci/
    └── tools/

The exact structure may evolve.

Do not create directories merely for aesthetics.

---

# 16. Coding Standards

Prefer:

- simple code
- explicit interfaces
- small components
- reproducible builds
- automated tests
- structured logging
- documented failure modes

Avoid:

- giant scripts
- hidden global state
- hardcoded paths
- hardcoded hardware assumptions
- unnecessary dependencies
- unnecessary daemons
- premature abstractions

Every new daemon or background service must have a documented reason.

---

# 17. Documentation Standards

Every significant architectural decision should be documented.

Use Architecture Decision Records when appropriate.

For example:

    docs/adr/0001-use-live-build.md
    docs/adr/0002-kde-wayland.md
    docs/adr/0003-runtime-resolution.md

Documentation should explain WHY, not only WHAT.

---

# 18. Testing

At minimum, test:

- ISO build
- ISO boot
- UEFI boot
- QEMU boot
- installer startup
- network detection
- disk detection
- hardware detection
- user creation
- package installation
- KDE startup
- Wayland session
- audio
- networking
- application launcher
- software center

Later test:

- Wine
- Proton
- Waydroid
- Windows VM
- macOS virtualization

All tests that require special hardware must be clearly marked.

---

# 19. QEMU Development Environment

QEMU is the primary development target.

The project should provide scripts for:

    ./tools/build-iso
    ./tools/run-qemu
    ./tools/run-qemu-install
    ./tools/test

The goal is:

    source code
        |
        v
    build ISO
        |
        v
    boot QEMU
        |
        v
    test
        |
        v
    iterate

No physical hardware should be required for basic development.

---

# 20. Change Discipline

Before implementing a large feature:

1. Research it.
2. Document it.
3. Define an interface.
4. Build a minimal proof of concept.
5. Test it.
6. Integrate it.

Do not implement an entire subsystem before proving the core
technical assumption.

---

# 21. Definition of Done

A feature is not complete merely because the code compiles.

A feature is complete when:

- it builds
- it works in QEMU when applicable
- failure cases are handled
- logs are useful
- documentation exists
- security implications are documented
- dependencies are documented
- installation/removal behavior is understood
- the user experience is coherent

---

# 22. Current Priority

The immediate goal is NOT:

> "Build the complete One Desktop. Every App. system."

The immediate goal is:

> Build a minimal, reproducible, Debian Trixie-based KDE Plasma
> Wayland Live ISO that boots reliably in QEMU.

Then build the installer.

Then build the native Linux experience.

Then integrate compatibility environments one at a time.

---

# 23. Agent Behavior

When working on this repository, the coding agent must:

- read `AGENTS.md`
- inspect existing code before modifying it
- research upstream projects when necessary
- avoid unnecessary rewrites
- keep commits logically scoped
- explain assumptions
- identify blockers
- never silently replace an architectural decision
- never claim functionality that has not been tested

When uncertain:

    research -> prototype -> document -> implement

not:

    guess -> implement -> hope

---

# 24. Final Principle

NextraOS should feel simple even when its implementation is complex.

The user should see:

    One Desktop.
    Every App.

The complexity belongs underneath the desktop.