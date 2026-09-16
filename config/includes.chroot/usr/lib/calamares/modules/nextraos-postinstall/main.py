#!/usr/bin/env python3
# NextraOS Post-Install Module
# Processes ecosystem selections from packagechooserq

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

    for item in selected:
        if item == "windows":
            _setup_windows_vm()
        elif item == "macos":
            _setup_macos_vm()
    
    return None

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
