#!/bin/bash
# Windows VM Management Script

set -e

VM_NAME="windows-vm"

# Check if VM exists
if ! virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    echo "Windows VM not found. Please create it first."
    echo "Example: virt-install --name $VM_NAME --memory 4096 --vcpus 2 ..."
    exit 1
fi

# Function to start the VM
start_vm() {
    if virsh domstate "$VM_NAME" | grep -q "running"; then
        echo "VM is already running."
    else
        echo "Starting Windows VM..."
        virsh start "$VM_NAME"
        echo "VM started. Use virt-manager or remote-viewer to connect."
    fi
}

# Function to stop the VM
stop_vm() {
    if virsh domstate "$VM_NAME" | grep -q "running"; then
        echo "Shutting down Windows VM..."
        virsh shutdown "$VM_NAME"
        echo "VM shutdown initiated."
    else
        echo "VM is not running."
    fi
}

# Function to show VM status
show_status() {
    echo "Windows VM Status:"
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

# Main
case "${1:-status}" in
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
        echo "Usage: $0 {start|stop|status|connect}"
        exit 1
        ;;
esac
