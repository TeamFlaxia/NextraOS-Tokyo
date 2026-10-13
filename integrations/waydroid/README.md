# Optional Waydroid single-desktop integration

Tested host: Debian 13, Niri 26.04, native Noctalia 5.2.1 and Waydroid 1.6.3
with Android 13 VANILLA x86_64. Android runs in one tiled Waydroid window;
Android apps remain inside its desktop. This is independent of Windows VMs.
No images, app data, accounts, device IDs or NVIDIA dependencies are included.
Install and initialize Waydroid through its upstream distribution instructions
before using this integration. It is not added to the default ISO profile.

## Launcher and Android preferences

```sh
./tools/install-flow-profile --with-waydroid --dry-run
./tools/install-flow-profile --with-waydroid
waydroid-window --print-size
waydroid-window
```

The optional flag copies the launcher, desktop entry and Android preferences
helper along with the Flow profile, using the same backups and path checks.
It does not install Android, change its data or stop/start the running session.
The launcher uses the focused Niri output's logical height, the configured gaps,
and visible Noctalia top/bottom bars on that output. It uses **height:width =
21:9**, rounded to pixels: 1080 - 48 - 2×14 gives 430×1004 on the tested host.
It recalculates on each launch; it does not monitor live window/output resizes.
This calculation assumes the exported Flow layout (no additional Niri struts).

The launcher starts the session on demand and changes size/single-window
properties only when necessary, restarting the session when they change.
A nonblocking lock prevents concurrent launches. Session startup output is
local under `~/.local/state/waydroid-desktop/`; nothing is uploaded.
The Flow Niri rule gives Waydroid the full available tile height.

With Android running, apply its internal window preferences as the desktop user:

```sh
waydroid-single-desktop
waydroid session stop
waydroid-window
```

This sets Android global `enable_freeform_support` and
`force_resizable_activities` to 0 through Waydroid's platform interface and
verifies both values. It unfreezes the container first. The helper uses the
Debian Waydroid Python modules at `/usr/lib/waydroid`; other distributions may
need that path adapted. To undo, set those Android preferences back to their
previous values; the helper is intended for this single-desktop setup.

For persistent host-side settings, review `properties.ini`, stop your Android
session, and explicitly run:

```sh
./tools/repair-waydroid-vendor --check
sudo ./tools/repair-waydroid-vendor
```

Without `--archive`, this updates only the single-desktop configuration and
regenerates Waydroid's derived configuration via `upgrade --offline`.
It removes old fixed dimensions and manual EGL/gralloc/Vulkan/DRM overrides,
leaving upstream GPU discovery and its software fallback intact. It does not
select an NVIDIA driver or hardcode a render device. The container service is
stopped during the operation and restored to its previous active/stopped state.
System image and Android app data are preserved. Backups are under
`/var/lib/waydroid/backups/single-desktop-<timestamp>`.

## Optional vendor regression repair

The original host's 20260927 MAINLINE vendor showed display instability.
[Upstream issue #2436](https://github.com/waydroid/waydroid/issues/2436) reports
that regression and a working 20260428 rollback on AMD Cezanne/Debian 13.
This is a targeted workaround, not a requirement for every new installation.

Download `lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip` from the
[official Waydroid image archive](https://sourceforge.net/projects/waydroid/files/images/vendor/waydroid_x86_64/lineage-20.0-20260428-MAINLINE-waydroid_x86_64-vendor.zip/download)
as your normal user. The [pinned official OTA metadata](https://raw.githubusercontent.com/waydroid/OTA/d3b9bcfdf60cf63c7f099d99f39f28de5c2149a3/vendor/waydroid_x86_64/MAINLINE.json)
specifies SHA256
`cba35433ffca73ed349e096b1daec495b3204e01c0e541c4203671e6d648e874`.
Use the actual downloaded path:

```sh
./tools/repair-waydroid-vendor --check --archive /path/to/vendor.zip
waydroid session stop
sudo ./tools/repair-waydroid-vendor --archive /path/to/vendor.zip
waydroid-window
```

The tool requires an existing x86_64 MAINLINE installation, privately copies
and hashes the ZIP before privileged use, checks the image size and extracts
only `vendor.img`. It backs up the original vendor and config, atomically
replaces the vendor, applies the single-desktop properties and pins `vendor_ota`
to the immutable official metadata. Failure after replacement restores both
files and reruns the offline configuration update. If recovery itself fails,
the exception is reported and the backup remains available for manual recovery.
Keep sufficient free space for the ZIP, extracted image, backup and replacement.
Do not run simultaneously with another Waydroid upgrade/repair.

The pin prevents ordinary upgrades from reinstalling the affected vendor.
Reassess it after an upstream fix: back up the configuration and set
`vendor_ota` back to `https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json`
before an intentional vendor upgrade. To restore a repair, stop the Android
session and container, restore the saved `vendor.img` (if present) and
`waydroid.cfg`, run `sudo waydroid upgrade --offline`, then restart the container
if it was previously active. Do not restore or delete Android app data.

The physical host previously exercised the portrait launcher and vendor
rollback. This export is checked using sizing/installer/rollback fixtures and
read-only verification of the official ZIP; it is not a new installation or
an ISO boot test. No administrative repair is automatically executed by tests.
