# NextraOS Niri package prototype

This directory contains a project-owned Debian packaging recipe for Niri
v26.04. It is deliberately separate from the live-build package lists: do
not integrate it into the ISO until runtime dependencies and the Niri +
Noctalia session pass QEMU validation.

## Pins and build

- Upstream tag: `v26.04` (unsigned; not trusted by itself)
- Required source commit: `8ed0da44d974c32c6877d2f4630c314da0717ecb`
- Rust upstream MSRV: 1.85
- Build entrypoint: `./tools/build-niri-package`

The builder refuses non-Trixie, non-AMD64, and root builds. It verifies the
checked-out commit, checks the package build dependencies, and runs
`cargo vendor --locked` from the pinned `Cargo.lock`. The generated Cargo
source-replacement config and vendor tree are then used for the package build
with `--frozen`/offline mode. The rules set `NIRI_BUILD_COMMIT` so the
compositor reports the exact source revision. The vendoring step needs network
access; the actual package build uses the vendored sources.

Set `NIRI_BUILD_JOBS` to cap parallel compilation when memory is limited.
The resulting `.deb` is placed in `dist/packages/` and is ignored by Git.
The package is not currently referenced by a live-build package list and is
not installed into the image. Debian Trixie does not package
`xwayland-satellite`; this recipe does not claim X11 application support. The
controls file uses a reserved `example.invalid` maintainer address; replace it
before publishing any package.

## Included upstream assets

The package recipe installs the compositor, upstream `niri-session`, the
Wayland session desktop entry, Niri's portal config, and the systemd user
service/shutdown target. The repository also contains two uninstalled session
prototypes: [`nextraos-config.kdl`](nextraos-config.kdl), which passed
`niri validate`, and [`noctalia-config.toml`](noctalia-config.toml), which the
separate Noctalia smoke test validates with the pinned shell CLI. The Niri
config expects `noctalia`, `foot`, and WirePlumber's `wpctl`; the Noctalia
profile selects Secret Service, enables its polkit agent and first-run wizard,
and disables telemetry, screen-time tracking, external-IP and exchange-rate
lookups. A GNOME Keyring provider and tested PAM unlock path are still required.
Neither config is installed by the current `.deb` or live-build. A greeter and
file manager are also not provided.

## Verification and release blockers

The first build completed in a fresh Debian Trixie/AMD64 container with the
listed build dependencies. `cargo test --frozen --release --package niri`
passed all 195 tests. Installing the resulting `.deb` in a fresh Trixie
runtime container resolved its declared dependencies; `niri --version`
reported the pinned commit, and the packaged session assets were present.
This is package-build/runtime smoke evidence, not a desktop-session result.

Before ISO integration:

1. Audit and package copyright/license notices for all statically linked Cargo
   dependencies; replace the reserved `example.invalid` Maintainer address.
2. Confirm runtime dependencies and systemd-user unit validation in the target
   image; keep the package out of live-build until that is complete.
3. Provide and validate NextraOS's Noctalia configuration, portal backends,
   terminal, file manager, and app-launch path.
4. Boot and test login, logout, graphics, audio, networking, portals,
   compositor failure/recovery, shutdown, and installation persistence in
   QEMU before removing the KDE prototype.
