#!/bin/bash
# macOS VM Management Script

set -e

VM_NAME="macos-vm"
OPENCORE_DIR="/usr/share/nextraos/opencore"
MACOS_DIR="/var/lib/libvirt/images/macos"

# Function to check if OpenCore is available
check_opencore() {
    if [ ! -d "$OPENCORE_DIR" ]; then
        echo "OpenCore not found. Please download it first."
        echo "Run: $0 download-opencore"
        return 1
    fi
    return 0
}

# Function to download OpenCore
download_opencore() {
    echo "Downloading OpenCore..."
    mkdir -p "$OPENCORE_DIR"
    
    # Download OpenCore ISO (using a known working version)
    echo "Note: OpenCore must be downloaded manually due to licensing."
    echo "Please download OpenCore from: https://github.com/acidanthera/OpenCorePkg/releases"
    echo "Extract the ISO to: $OPENCORE_DIR"
    echo ""
    echo "Alternatively, you can use the macOS-Simple-KVM project:"
    echo "  git clone https://github.com/foxlet/macOS-Simple-KVM.git"
    echo "  cp macOS-Simple-KVM/OpenCore/OC_*.img $OPENCORE_DIR/"
}

# Function to download macOS Recovery
download_recovery() {
    echo "Downloading macOS Recovery..."
    mkdir -p "$MACOS_DIR"
    
    # Use macOS Recovery script
    if command -v macrecovery &> /dev/null; then
        macrecovery download -o "$MACOS_DIR"
    else
        echo "macrecovery not found. Installing..."
        # Install macrecovery if available
        if command -v pip3 &> /dev/null; then
            pip3 install macrecovery
            macrecovery download -o "$MACOS_DIR"
        else
            echo "Please install macrecovery manually:"
            echo "  pip3 install macrecovery"
            echo "  macrecovery download -o $MACOS_DIR"
        fi
    fi
}

# Function to create macOS VM
create_vm() {
    echo "Creating macOS VM..."
    
    # Check if VM exists
    if virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
        echo "VM already exists. Use 'start' to start it."
        return 1
    fi
    
    # Create VM using virt-install
    virt-install \
        --name "$VM_NAME" \
        --memory 8192 \
        --vcpus 4 \
        --cpu Skylake-Client-v4 \
        --os-type linux \
        --disk path="$MACOS_DIR/macOS.qcow2",size=128,format=qcow2 \
        --cdrom "$OPENCORE_DIR/OpenCore.iso" \
        --boot uefi \
        --network network=default \
        --graphics spice \
        --video qxl \
        --sound ich9 \
        --virt-type kvm
    
    echo "VM created. Use 'start' to start it."
}

# Function to start the VM
start_vm() {
    if virsh domstate "$VM_NAME" | grep -q "running"; then
        echo "VM is already running."
    else
        echo "Starting macOS VM..."
        virsh start "$VM_NAME"
        echo "VM started. Use virt-manager or remote-viewer to connect."
    fi
}

# Function to stop the VM
stop_vm() {
    if virsh domstate "$VM_NAME" | grep -q "running"; then
        echo "Shutting down macOS VM..."
        virsh shutdown "$VM_NAME"
        echo "VM shutdown initiated."
    else
        echo "VM is not running."
    fi
}

# Function to show VM status
show_status() {
    echo "macOS VM Status:"
    virsh dominfo "$VM_NAME" 2>/dev/null || echo "VM not found"
}

# Function to connect via SPICE
connect_spice() {
    local port=$(virsh domdisplay "$VM_NAME" 2>/dev/null)
    if [ -n "$port" ]; then
        echo "Connecting to VM via SPICE..."
        remote-viewer "$port"
    else
        echo "VM is not running or SPICE is not available."
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 {download-opencore|download-recovery|create|start|stop|status|connect}"
    echo ""
    echo "Commands:"
    echo "  download-opencore  Download OpenCore bootloader"
    echo "  download-recovery  Download macOS Recovery DMG"
    echo "  create            Create a new macOS VM"
    echo "  start             Start the macOS VM"
    echo "  stop              Stop the macOS VM"
    echo "  status            Show VM status"
    echo "  connect           Connect to VM via SPICE"
}

# Main
case "${1:-}" in
    download-opencore)
        download_opencore
        ;;
    download-recovery)
        download_recovery
        ;;
    create)
        create_vm
        ;;
    start)
        start_vm
        ;;
    stop)
        stop_vm
        ;;
    status)
        show_status
        ;;
    connect)
        connect_spice
        ;;
    *)
        show_help
        exit 1
        ;;
esac
