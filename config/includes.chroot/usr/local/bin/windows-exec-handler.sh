#!/bin/bash
# Script to handle Windows executables
# This script is called when a user tries to open a .exe or .msi file

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

# Check if Windows VM is running
if ! virsh domstate windows-vm 2>/dev/null | grep -q "running"; then
    echo "Windows VM is not running."
    echo "Starting Windows VM..."
    virsh start windows-vm 2>/dev/null || {
        echo "Failed to start Windows VM."
        echo "Please create a Windows VM first using virt-manager."
        exit 1
    }
    echo "Waiting for Windows VM to start..."
    sleep 10
fi

# Get the SPICE port
SPICE_PORT=$(virsh domdisplay windows-vm 2>/dev/null | grep -oP 'spice://\K[^:]+')

if [ -z "$SPICE_PORT" ]; then
    echo "Cannot determine SPICE port."
    exit 1
fi

echo "Windows VM is running."
echo "To run Windows applications:"
echo "1. Connect to the VM using virt-manager or remote-viewer"
echo "2. Copy the file to the VM using shared folder or SPICE clipboard"
echo "3. Run the application inside the VM"
echo ""
echo "SPICE Connection: spice://localhost:$SPICE_PORT"
