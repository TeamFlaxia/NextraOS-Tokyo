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

- Waydroid
- QEMU
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
- Niri + Noctalia
- Wayland
- PipeWire
- Waydroid
- QEMU
- KVM
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

> "Linux cannot run that."

must not be made without verification.

---

# 3. Base System

The current Tokyo target is:

- Debian 13 (Trixie)
- AMD64 / x86_64
- Niri Wayland compositor
- Noctalia v5 desktop shell
- systemd
- PipeWire
- NetworkManager
- APT / dpkg
- Persistent installed system

The checked-in KDE image is a historical prototype, not the target
architecture. Do not claim the Niri + Noctalia transition is complete
until its package source, login session, portals, audio, networking,
and QEMU boot are verified.

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

## Stage 0 — Debian Baseline

Build a minimal Debian Trixie/AMD64 rootfs with `live-build` and record
its package set, startup services, boot time and memory baseline. Research
upstream dependencies, licenses, security models and package provenance
before adding non-Debian components.

---

## Stage 1 — Wayland Desktop

Produce a QEMU-bootable UEFI image with Niri + Noctalia v5, a safe login
session, portals, PipeWire/WirePlumber, NetworkManager, terminal, file
manager and basic settings. Verify login/logout, graphics, audio,
networking, app launch, shutdown and compositor-failure behavior before
removing the KDE prototype.

---

## Stage 2 — Memory Optimization

Measure 4 GB, 8 GB and 16 GB profiles at 5/30/60 minutes after repeated
cold boots under the fixed conditions in `docs/MEMORY-BENCHMARK.md`.
The host idle target is below 1024 MiB; 850 MiB is a development goal.
Record misses honestly. Do not drop caches, hide swap use or disable
security features to reach a number.

---

## Stage 3 — Android

Integrate Waydroid only when selected and started. Verify initialization,
image download, APK install, application discovery, data persistence,
stop/restart, Wayland integration and filesystem/clipboard boundaries.

---

## Stage 4 — Virtualization

Integrate QEMU/KVM via libvirt and local socket activation. Windows
applications use an explicitly started full Windows VM. Verify create,
start, shutdown, suspend, SPICE, persistence and resource limits. Guest
filesystem/device access remains opt-in.

---

## Stage 5 — Performance Tuning

Tune kernel modules, initramfs, zram, startup services, GPU, CPU and VM
I/O only after collecting a baseline. Retain changes only when repeatable
tests show an improvement without security, stability or usability loss.

---

## Stage 6 — Installer and Distribution

Maintain a network-first installer that detects hardware/network, collects
user and locale settings, lets users select runtimes/apps, calculates
actual disk requirements, installs the system, and verifies first boot.
Test installed-system persistence across reboot. The installer selection
must control component installation; avoid shipping every large runtime
in the ISO by default.

---

## Experimental macOS Research

Investigate QEMU/KVM compatibility, AVX2/hardware requirements, licensing
and legal distribution restrictions separately. Support remains
experimental; never distribute proprietary Apple software or copyrighted
system images, and do not imply guaranteed compatibility.

---

# 6. Hardware Profiles

NextraOS uses the Tokyo project plan's 4/8/16 GB RAM profiles.

## Limited Mode

- AMD64-compatible CPU
- 4 GB RAM
- Basic desktop and one constrained guest/runtime at a time

Do not imply that Android and a full VM can be used concurrently at
this profile. The 4 GB target is part of the idle-memory test matrix,
not a promise of full-feature multitasking.

---

## Full-Feature Minimum

- 8 GB RAM
- Hardware virtualization enabled for KVM guests
- Guest and package choices must be reflected in actual disk-space estimates

This is the minimum practical profile for the complete feature set,
not a comfortable multitasking recommendation.

AVX2 is NOT a requirement for the basic NextraOS desktop. It may be
required for specific experimental virtualization scenarios and must
be assessed per guest configuration.

---

## Recommended

- 16 GB RAM or more
- NVMe preferred
- Hardware virtualization enabled

32 GB or more is preferred for users who intend to run multiple heavy
environments (Android, VMs, development tools, and browsers) together.
Storage requirements depend on selected components and guest images;
the installer must calculate them instead of presenting a universal
128 GB minimum.

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

Idle host memory target: below 1024 MiB; 850 MiB is a development goal.
Both are unverified until measured at 5/30/60 minutes after multiple
cold boots under the fixed conditions in `docs/MEMORY-BENCHMARK.md`.
Report PSS, swap, zram, PSI, boot timing and GPU/UMA memory behavior
(manual if needed); never hide memory pressure by dropping caches or
disabling security features.

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
        [x] Windows VM (QEMU/KVM)

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

    Niri + Noctalia v5 + Wayland

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
    └── Windows VM

    Android Apps
    └── Waydroid

    Virtualization
    └── QEMU / KVM

The exact launcher/menu implementation may change.

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
3. Waydroid
4. Windows VM
5. macOS virtualization

This ordering is not absolute.

The resolver should consider application-specific compatibility.

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
    docs/adr/0002-niri-noctalia-wayland.md
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
- Niri + Noctalia session startup
- Wayland session and portals
- audio
- networking
- application launcher
- software center

Later test:

- Waydroid
- Windows VM
- macOS virtualization

All tests that require special hardware must be clearly marked.

---

# 19. QEMU Development Environment

QEMU is the primary development target.

The project should provide scripts for:

    ./build/build-iso
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

> Build a minimal, reproducible Debian Trixie AMD64 image with a
> verified Niri + Noctalia v5 Wayland session that boots in QEMU.

The checked-in KDE image is a historical prototype, not evidence that
the Tokyo desktop target is complete. After the Niri session proof,
measure the 4/8/16 GB idle baselines, then improve installation,
persistence, and on-demand runtime integration one component at a time.

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