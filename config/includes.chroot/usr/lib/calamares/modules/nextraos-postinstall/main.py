#!/usr/bin/env python3
# NextraOS Post-Install Module
# Processes ecosystem selections from packagechooserq

import os
import libcalamares

def pretty_name():
    return "NextraOS Post-Install Configuration"

def run():
    """Process ecosystem selections and configure the installed system."""
    selections = libcalamares.globalstorage.value("packagechooser_packagechooserq")
    
    if not selections:
        libcalamares.utils.warning("No ecosystem selections found")
        return None
    
    # selections is a comma-separated string of selected IDs
    selected = [s.strip() for s in selections.split(",") if s.strip()]

    libcalamares.utils.debug("NextraOS post-install: selected ecosystems: {}".format(selected))

    _setup_flatpak()

    android_type = _android_system_type(selected)
    if android_type:
        _persist_android_system_type(android_type)

    for item in selected:
        if item == "windows":
            _setup_windows_vm()
        elif item == "macos":
            _setup_macos_vm()

    _remove_installer()

    return None

def _android_system_type(selected):
    """Return GAPPS/VANILLA for Android tokens, or None."""
    if "android-gapps" in selected:
        return "GAPPS"
    if "android-vanilla" in selected or "android" in selected:
        return "VANILLA"
    return None

def _persist_android_system_type(system_type):
    """Write /etc/waydroid/system_type for first-boot init."""
    root = libcalamares.globalstorage.value("rootMountPoint")
    if not root:
        return
    path = os.path.join(root, "etc/waydroid/system_type")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(system_type + "\n")
        libcalamares.utils.debug(
            "Android system type persisted: {}".format(system_type)
        )
    except Exception as e:
        libcalamares.utils.warning(
            "Failed to persist Android system type: {}".format(str(e))
        )

def _setup_flatpak():
    """Configure Flatpak with Flathub repository."""
    try:
        libcalamares.utils.check_target_env_call([
            "flatpak", "remote-add", "--if-not-exists",
            "flathub", "https://flathub.org/repo/flathub.flatpakrepo"
        ])
        libcalamares.utils.debug("Flatpak Flathub configured")
    except Exception as e:
        libcalamares.utils.warning("Flatpak setup failed: {}".format(str(e)))

def _setup_windows_vm():
    """Configure Windows VM support."""
    try:
        libcalamares.utils.check_target_env_call(["systemctl", "enable", "libvirtd"])
        libcalamares.utils.debug("libvirtd enabled for Windows VM")
    except Exception as e:
        libcalamares.utils.warning("Windows VM setup failed: {}".format(str(e)))

def _setup_macos_vm():
    """Configure macOS VM support (experimental)."""
    try:
        libcalamares.utils.check_target_env_call(["systemctl", "enable", "libvirtd"])
        libcalamares.utils.debug("libvirtd enabled for macOS VM (experimental)")
    except Exception as e:
        libcalamares.utils.warning("macOS VM setup failed: {}".format(str(e)))

def _remove_installer():
    """Remove Calamares installer from the installed system."""
    root = libcalamares.globalstorage.value("rootMountPoint")
    if not root:
        libcalamares.utils.warning("No root mount point found, skipping installer removal")
        return

    files_to_remove = [
        os.path.join(root, "etc/xdg/autostart/calamares.desktop"),
        os.path.join(root, "usr/share/applications/calamares.desktop"),
        os.path.join(root, "usr/share/applications/nextraos-installer.desktop"),
        os.path.join(root, "etc/sudoers.d/calamares"),
        os.path.join(root, "usr/local/bin/nextraos-postinstall"),
    ]

    dirs_to_remove = [
        os.path.join(root, "usr/lib/calamares/modules/nextraos-postinstall"),
        os.path.join(root, "usr/lib/calamares/modules/waydroid-image-download"),
        os.path.join(root, "etc/calamares"),
    ]

    for path in files_to_remove:
        try:
            if os.path.exists(path):
                os.remove(path)
                libcalamares.utils.debug("Removed {}".format(path))
        except Exception as e:
            libcalamares.utils.warning("Failed to remove {}: {}".format(path, str(e)))

    for path in dirs_to_remove:
        try:
            if os.path.exists(path):
                import shutil
                shutil.rmtree(path)
                libcalamares.utils.debug("Removed {}".format(path))
        except Exception as e:
            libcalamares.utils.warning("Failed to remove {}: {}".format(path, str(e)))

    try:
        libcalamares.utils.check_target_env_call(
            ["update-desktop-database", "/usr/share/applications"]
        )
    except Exception:
        pass

    libcalamares.utils.debug("NextraOS installer removed from installed system")
