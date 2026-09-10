# NextraOS Installer

## Philosophy

The installer is network-first.

The ISO should contain enough software to:

- boot
- display the installer
- detect hardware
- establish networking
- partition/install the base system

Optional components should be downloaded after the user selects them.

---

# Installation Flow

## 1. Welcome

    NextraOS Installer

    Welcome to NextraOS!
    Let's install it!

    [Continue]

---

# 2. User

    What's your name?

    Username:
    [________________]

    Password:
    [________________]

    Confirm password:
    [________________]

    [Continue]

---

# 3. Language and Time

    Language
    [ English (United States) ]

    Keyboard
    [ US ]

    Timezone
    [ Asia/Tokyo ]

    [Continue]

---

# 4. Application Ecosystems

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

The UI should show only relevant requirements.

---

# 5. Requirements

The installer should dynamically calculate requirements.

Example:

    Selected:
        Linux
        Android
        Windows compatibility

    Required:
        8 GB RAM recommended
        XX GB storage

If Windows VM is selected:

    Additional storage:
        XX GB

If macOS virtualization is selected:

    AVX2:
        Required

    KVM:
        Required

The installer must distinguish:

- hard requirement
- recommendation
- warning
- experimental capability

---

# 6. Starter Kit

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

The default selection should be conservative.

---

# 7. Storage

Display actual disks.

Example:

    Toshiba 1TB
    931 GB available
    Recommended

    Install disk 16GB
    Not enough space for selected components

The installer must account for:

- base OS
- selected applications
- compatibility runtimes
- VM images
- filesystem overhead
- future update space

---

# 8. Installation

The installation process should be transactional where practical.

Suggested sequence:

1. validate selections
2. validate hardware
3. validate network
4. partition disk
5. install Debian base
6. install KDE
7. install selected runtimes
8. install selected applications
9. configure services
10. create user
11. create desktop integration
12. run post-install checks
13. generate boot configuration
14. finish

---

# 9. Failure Handling

If installation fails:

- preserve useful logs
- explain what failed
- provide recovery options
- avoid leaving the disk in an ambiguous state

Logs should be available from the installer environment.

---

# 10. Offline Mode

NextraOS is designed for Internet-first installation.

If offline installation is eventually supported, it should be limited.

The installer should clearly communicate:

    Internet connection unavailable.

    You can continue with a minimal installation,
    but optional compatibility environments and
    applications cannot be downloaded now.

The project should not attempt to ship every package in the ISO
just to support offline installation.