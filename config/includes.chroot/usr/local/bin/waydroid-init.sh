#!/bin/bash
set -e

WAYDROID_MARKER="/var/lib/waydroid/.initialized"

# Check if already initialized
if [ -f "$WAYDROID_MARKER" ]; then
    echo "Waydroid already initialized, skipping..."
    exit 0
fi

echo "==> First-time Waydroid initialization"

# Check if binder module is available
if ! modprobe -n binder_linux 2>/dev/null; then
    echo "Warning: binder_linux module not available. Waydroid may not work."
    echo "Please ensure your kernel supports binder."
fi

# Verify all required binder nodes exist
BINDER_MISSING=0
for node in binder vndbinder hwbinder; do
    if [ ! -e "/dev/$node" ] && [ ! -e "/dev/binderfs/$node" ]; then
        echo "Warning: /dev/$node not found. Attempting to create..."
        BINDER_MISSING=1
    fi
done

if [ "$BINDER_MISSING" -eq 1 ]; then
    # Ensure binderfs is mounted
    if ! mountpoint -q /dev/binderfs 2>/dev/null; then
        modprobe binder_linux devices="binder,hwbinder,vndbinder" 2>/dev/null || true
        mkdir -p /dev/binderfs
        mount -t binder binder /dev/binderfs 2>/dev/null || true
    fi
    # Symlink binderfs nodes to /dev
    ln -sf /dev/binderfs/* /dev/ 2>/dev/null || true
fi

# Final check before proceeding
for node in binder vndbinder hwbinder; do
    if [ ! -e "/dev/$node" ]; then
        echo "ERROR: Required binder node /dev/$node not found."
        echo "Waydroid requires binder, vndbinder, and hwbinder nodes."
        echo "Ensure your kernel has binder_linux module support."
        exit 1
    fi
done

# Initialize Waydroid (downloads system image on first run)
echo "Initializing Waydroid..."
waydroid init

# Create desktop entries for Android apps
echo "Creating desktop entries for Android apps..."
/usr/local/bin/waydroid-desktop-entries.sh

# Mark as initialized
touch "$WAYDROID_MARKER"

echo "==> Waydroid initialization complete"
