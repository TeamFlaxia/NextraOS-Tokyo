#!/bin/bash
# Script to handle Windows executables
# Called when a user tries to open a .exe or .msi file

set -e

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <windows-executable>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

# Ensure disk exists, then launch via the canonical VM manager
if [ ! -f "$HOME/.local/share/nextraos/vms/windows/disk.qcow2" ]; then
    echo "==> Creating Windows VM disk..."
    nextraos-vm create windows
fi

if ! ls "$HOME/.local/share/nextraos/vms/windows/"*.iso >/dev/null 2>&1; then
    echo "==> Windows ISO not found. Run: nextraos-vm download-iso windows"
    echo "    (Downloads from the Microsoft CDN — review Microsoft's EULA first.)"
    exit 1
fi

if ! virsh dominfo windows >/dev/null 2>&1; then
    echo "==> Windows VM is not running. Starting..."
    nextraos-vm start windows
fi

echo "==> Launching in Windows VM: $FILE"
nextraos-vm execute windows "$FILE"
