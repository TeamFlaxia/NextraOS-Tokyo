#!/bin/bash
# Script to create desktop entries for Android apps
# This runs after Waydroid is initialized

WAYDROID_DATA="/var/lib/waydroid/data"
DESKTOP_DIR="/usr/share/applications"

# Check if Waydroid is initialized
if [ ! -d "$WAYDROID_DATA" ]; then
    echo "Waydroid not initialized yet, skipping desktop entry creation"
    exit 0
fi

# Find installed Android packages
for pkg in $(ls "$WAYDROID_DATA/app/" 2>/dev/null); do
    # Get package info from Android manifest
    if [ -f "$WAYDROID_DATA/app/$pkg/base.apk" ]; then
        # Create a basic desktop entry
        cat > "$DESKTOP_DIR/android-$pkg.desktop" << EOF
[Desktop Entry]
Name=$pkg
Comment=Android Application
Exec=waydroid app launch $pkg
Icon=android-app
Terminal=false
Type=Application
Categories=Utilities;
Keywords=android;app;
EOF
    fi
done
