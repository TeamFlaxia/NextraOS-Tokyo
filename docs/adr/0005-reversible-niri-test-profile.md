# ADR 0005: Reversible Niri desktop smoke profile

- Status: Accepted for an unverified test profile; not a production image decision
- Context: The repository's default live-build configuration is a historical KDE prototype, while the Tokyo target is Niri + Noctalia. The Niri session must be proven in QEMU before the KDE fallback is removed. Noctalia is supplied by a community-maintained Debian archive, not Debian.

## Decision

Build the Niri desktop smoke image from a disposable project copy using `build/build-niri-test-iso`. Replace only the staged desktop package list, omit application/Waydroid/VM/installer packages and legacy feature hooks, and seed the Niri/Noctalia prototypes under `/etc/skel`. The root KDE desktop package list remains selected until the QEMU gate passes. The staging helper does not edit it; separate shared Waydroid/libvirt lifecycle hooks in the current worktree have on-demand activation changes, so the entire default KDE image is not otherwise byte-for-byte unchanged.

Use the pinned local Niri `.deb` and exact Noctalia package version. Add the Noctalia source, key and origin/version pins with live-build's `.chroot` suffixes and `Signed-By` scoping; do not add `.binary` source/key files to the target system. Seed Debian CA roots during debootstrap so the first HTTPS APT index update can validate the archive certificate, and keep `ca-certificates` installed. The profile selects greetd + tuigreet instead of SDDM, plus PipeWire/WirePlumber, NetworkManager, GNOME/GTK portals, Nautilus, GNOME Keyring/PAM, `foot`, polkit, zram and unattended upgrades. It disables APT recommendations and explicitly lists the Noctalia recommendations retained for the test.

## Rationale

- Staging protects the historical KDE configuration and allows a real Niri image attempt without claiming the transition is complete.
- Niri's upstream screencasting guidance requires `xdg-desktop-portal-gnome`; its pinned portal config routes Secret Service to GNOME Keyring. These are explicit dependencies, not optional guesses.
- A Trixie/AMD64 package simulation selected 485 new-package actions with SDDM versus 420 with greetd + tuigreet for the same candidate desktop dependencies. The initial complete test list resolved 451 package-install actions before explicit `ca-certificates` bootstrap was added; rerun for the current package list. These counts are not installed RAM or running-process measurements.
- A TUI greeter is an intentional early tradeoff to avoid the SDDM/Xorg package closure. Revisit the user experience after login/session behavior is proven.
- The old production-hardening hook is excluded from this smoke image: it installs unrelated diagnostics and opens SSH/VNC firewall ports. Design a separate, reviewed security policy before using the profile for a release.
- Chroot-only archive configuration reduces the chance of leaving the community source/key trusted on the installed system; it does not remove the need for controlled mirroring, license review, key rotation and update policy before release.

## Consequences

- The smoke profile omits Calamares and persistence, Waydroid, VM runtimes, Flatpak and starter-kit applications. It proves only a live desktop package/login path if it builds and boots.
- The profile requires a previously built `dist/packages/nextraos-niri_26.04-1_amd64.deb`, live-build, network access and build privileges.
- The profile has not yet produced or booted an ISO. Login/logout, graphics, portals, audio, networking, launcher/app discovery, shutdown, compositor failure and keyring unlock remain QEMU tests.
- The 4/8/16 GiB idle-memory gate and persistent installation remain later milestones.

## References

- Niri screencasting and portal requirements: <https://niri-wm.github.io/niri/Screencasting.html>
- Pinned Niri portal defaults: <https://raw.githubusercontent.com/niri-wm/niri/8ed0da44d974c32c6877d2f4630c314da0717ecb/resources/niri-portals.conf>
- Noctalia Secret Service/keyring configuration: <https://docs.noctalia.dev/noctalia/configuration/secret-service/>
- Debian greetd: <https://packages.debian.org/trixie/greetd>
- Debian tuigreet: <https://packages.debian.org/trixie/tuigreet>
