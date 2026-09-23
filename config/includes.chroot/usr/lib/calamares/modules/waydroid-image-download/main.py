#!/usr/bin/env python3
# NextraOS Waydroid Image Download Module
# Downloads Waydroid system and vendor images during installation
# Supports GAPPS and VANILLA system types selected in packagechooserq

import json
import libcalamares
import os
import subprocess
import tempfile

WAYDROID_OTA_SYSTEM = {
    "GAPPS": "https://ota.waydro.id/system/lineage/waydroid_x86_64/GAPPS.json",
    "VANILLA": "https://ota.waydro.id/system/lineage/waydroid_x86_64/VANILLA.json",
}
WAYDROID_OTA_VENDOR = "https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json"


def pretty_name():
    return "Waydroid Image Download"


def _parse_android_system_type(selections):
    """Return GAPPS or VANILLA from packageChoice, or None if Android not selected.

    Legacy token "android" maps to VANILLA (matches waydroid upstream default).
    """
    if not selections:
        return None
    tokens = [s.strip() for s in selections.split(",") if s.strip()]
    if "android-gapps" in tokens:
        return "GAPPS"
    if "android-vanilla" in tokens:
        return "VANILLA"
    if "android" in tokens:
        return "VANILLA"
    return None


def run():
    """Download Waydroid images if Android ecosystem was selected."""
    selections = libcalamares.globalstorage.value("packagechooser_packagechooserq")
    system_type = _parse_android_system_type(selections)
    if not system_type:
        libcalamares.utils.debug("Android not selected, skipping Waydroid image download")
        return None

    root_mount = libcalamares.globalstorage.value("rootMountPoint")
    if not root_mount:
        libcalamares.utils.warning("No root mount point found")
        return None

    target_images_dir = os.path.join(root_mount, "etc/waydroid-extra/images")
    system_type_file = os.path.join(root_mount, "etc/waydroid/system_type")

    # Persist choice for first-boot waydroid-init.sh
    try:
        os.makedirs(os.path.dirname(system_type_file), exist_ok=True)
        with open(system_type_file, "w") as f:
            f.write(system_type + "\n")
        libcalamares.utils.debug(
            "Persisted Waydroid system type: {}".format(system_type)
        )
    except Exception as e:
        libcalamares.utils.warning(
            "Failed to write system_type file: {}".format(str(e))
        )

    # Check network connectivity
    if not _check_network():
        libcalamares.utils.warning(
            "No network connectivity. Waydroid images will be downloaded on first boot."
        )
        return None

    libcalamares.utils.debug(
        "Downloading Waydroid {} images...".format(system_type)
    )

    os.makedirs(target_images_dir, exist_ok=True)

    system_ota = WAYDROID_OTA_SYSTEM[system_type]

    libcalamares.utils.debug("Fetching system image info from OTA...")
    system_url = _fetch_image_url(system_ota)
    if system_url:
        _download_and_extract(system_url, target_images_dir, "system")
    else:
        libcalamares.utils.warning("Failed to get system image URL from OTA")

    libcalamares.utils.debug("Fetching vendor image info from OTA...")
    vendor_url = _fetch_image_url(WAYDROID_OTA_VENDOR)
    if vendor_url:
        _download_and_extract(vendor_url, target_images_dir, "vendor")
    else:
        libcalamares.utils.warning("Failed to get vendor image URL from OTA")

    libcalamares.utils.debug("Initializing Waydroid with local images...")
    try:
        libcalamares.utils.check_target_env_call(
            ["waydroid", "init", "-f", "-s", system_type]
        )
        libcalamares.utils.debug("Waydroid initialized with pre-downloaded images")
    except Exception as e:
        libcalamares.utils.warning(
            "Waydroid init failed (will retry on first boot): {}".format(str(e))
        )

    return None


def _check_network():
    """Check if network connectivity is available."""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "3", "ota.waydro.id"],
            capture_output=True,
            timeout=10,
        )
        return result.returncode == 0
    except Exception:
        return False


def _fetch_image_url(ota_url):
    """Fetch the latest image download URL from Waydroid OTA API."""
    try:
        result = subprocess.run(
            ["curl", "-sL", "--max-time", "30", ota_url],
            capture_output=True,
            timeout=35,
        )
        if result.returncode != 0:
            libcalamares.utils.warning(
                "Failed to fetch OTA info from {}: curl error {}".format(
                    ota_url, result.returncode
                )
            )
            return None

        data = json.loads(result.stdout.decode("utf-8"))
        response = data.get("response", [])
        if not response:
            libcalamares.utils.warning("Empty OTA response from {}".format(ota_url))
            return None

        latest = response[0]
        url = latest.get("url")
        filename = latest.get("filename", "unknown")
        size_mb = latest.get("size", 0) / (1024 * 1024)

        libcalamares.utils.debug(
            "Found image: {} ({:.0f} MB)".format(filename, size_mb)
        )
        return url

    except json.JSONDecodeError as e:
        libcalamares.utils.warning("Failed to parse OTA JSON: {}".format(str(e)))
        return None
    except Exception as e:
        libcalamares.utils.warning(
            "Failed to fetch image URL from {}: {}".format(ota_url, str(e))
        )
        return None


def _download_and_extract(url, target_dir, label):
    """Download a zip file and extract it to the target directory."""
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            zip_path = os.path.join(tmpdir, "image.zip")

            libcalamares.utils.debug("Downloading {} image...".format(label))

            result = subprocess.run(
                [
                    "curl",
                    "-L",
                    "--progress-bar",
                    "--max-time",
                    "1800",
                    "-o",
                    zip_path,
                    url,
                ],
                timeout=1810,
            )
            if result.returncode != 0:
                libcalamares.utils.warning(
                    "Failed to download {} image: curl error {}".format(
                        label, result.returncode
                    )
                )
                return

            libcalamares.utils.debug(
                "Extracting {} image to {}...".format(label, target_dir)
            )

            result = subprocess.run(
                ["unzip", "-o", zip_path, "-d", target_dir],
                capture_output=True,
                timeout=300,
            )
            if result.returncode != 0:
                libcalamares.utils.warning(
                    "Failed to extract {} image: {}".format(
                        label, result.stderr.decode("utf-8", errors="replace")
                    )
                )
                return

            libcalamares.utils.debug("{} image ready".format(label))

    except subprocess.TimeoutExpired:
        libcalamares.utils.warning("Timeout downloading {} image".format(label))
    except Exception as e:
        libcalamares.utils.warning(
            "Failed to process {} image: {}".format(label, str(e))
        )
