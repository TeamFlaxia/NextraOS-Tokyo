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

# Initialize Waydroid (downloads system image on first run)
echo "Initializing Waydroid..."
waydroid init

# Create desktop entries for Android apps
echo "Creating desktop entries for Android apps..."
/usr/local/bin/waydroid-desktop-entries.sh

# Mark as initialized
touch "$WAYDROID_MARKER"

echo "==> Waydroid initialization complete"
