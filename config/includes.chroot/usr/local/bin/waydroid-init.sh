#!/bin/bash
set -e

WAYDROID_MARKER="/var/lib/waydroid/.initialized"

# Check if already initialized
if [ -f "$WAYDROID_MARKER" ]; then
    echo "Waydroid already initialized, skipping..."
    exit 0
fi

echo "==> First-time Waydroid initialization"

# --- Binder Setup ---
# Try multiple methods to get binder working:
# 1. binderfs already mounted
# 2. Mount binderfs (works if kernel has binderfs built-in)
# 3. Load binder_linux module (may fail on SecureBoot)
# 4. Fail with clear error message

setup_binder() {
    # Check if binder nodes already exist
    local all_exist=true
    for node in binder vndbinder hwbinder; do
        if [ ! -e "/dev/$node" ] && [ ! -e "/dev/binderfs/$node" ]; then
            all_exist=false
            break
        fi
    done

    if $all_exist; then
        echo "Binder nodes already available."
        return 0
    fi

    echo "Setting up binder..."

    # Method 1: Try mounting binderfs (no module needed if kernel has it built-in)
    if ! mountpoint -q /dev/binderfs 2>/dev/null; then
        mkdir -p /dev/binderfs
        if mount -t binder binder /dev/binderfs 2>/dev/null; then
            echo "binderfs mounted successfully."
            ln -sf /dev/binderfs/* /dev/ 2>/dev/null || true
            return 0
        fi
        rmdir /dev/binderfs 2>/dev/null || true
    fi

    # Method 2: Try loading binder_linux module
    echo "binderfs mount failed, trying modprobe..."
    if modprobe binder_linux devices="binder,hwbinder,vndbinder" 2>/dev/null; then
        echo "binder_linux module loaded."
        # If binderfs is available, mount it
        mkdir -p /dev/binderfs
        mount -t binder binder /dev/binderfs 2>/dev/null || true
        ln -sf /dev/binderfs/* /dev/ 2>/dev/null || true
        return 0
    fi

    # Method 3: Module load failed (possibly SecureBoot)
    echo ""
    echo "WARNING: Could not load binder module."
    echo "This may be caused by SecureBoot blocking unsigned modules."
    echo ""
    echo "Possible solutions:"
    echo "  1. Disable SecureBoot in BIOS/UEFI settings"
    echo "  2. Enroll MOK and sign the binder module (see NextraOS docs)"
    echo "  3. Use a kernel with binder support built-in"
    echo ""

    # Check if any binder nodes exist after our attempts
    for node in binder vndbinder hwbinder; do
        if [ ! -e "/dev/$node" ] && [ ! -e "/dev/binderfs/$node" ]; then
            echo "ERROR: Required binder node /dev/$node not found."
            echo "Waydroid will not work without binder support."
            echo "Continuing anyway - Waydroid may work on first boot if binder is configured."
            return 1
        fi
    done

    return 0
}

setup_binder || true

# --- Waydroid Initialization ---

# Initialize Waydroid (uses pre-downloaded images if available)
WAYDROID_EXTRA_IMAGES="/etc/waydroid-extra/images"
if [ -d "$WAYDROID_EXTRA_IMAGES" ] && [ "$(ls -A $WAYDROID_EXTRA_IMAGES 2>/dev/null)" ]; then
    echo "Using pre-downloaded Waydroid images from $WAYDROID_EXTRA_IMAGES"
    waydroid init -f
else
    echo "No pre-downloaded images found, downloading from internet..."
    waydroid init
fi

# --- Multi-window Mode ---
# Enable multi-window mode for better desktop integration
echo "Enabling multi-window mode..."
waydroid prop set persist.waydroid.multi_windows true 2>/dev/null || true

# --- Desktop Integration ---

# Create desktop entries for Android apps
echo "Creating desktop entries for Android apps..."
/usr/local/bin/waydroid-desktop-entries.sh

# Mark as initialized
touch "$WAYDROID_MARKER"

echo "==> Waydroid initialization complete"
