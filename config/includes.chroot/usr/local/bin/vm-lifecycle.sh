#!/bin/bash
# VM Lifecycle Management Script

set -e

# Function to suspend a VM
suspend_vm() {
    local vm_name="$1"
    
    if [ -z "$vm_name" ]; then
        echo "Usage: $0 suspend <vm-name>"
        return 1
    fi
    
    if ! virsh domstate "$vm_name" | grep -q "running"; then
        echo "VM '$vm_name' is not running."
        return 1
    fi
    
    echo "Suspending VM '$vm_name'..."
    virsh suspend "$vm_name"
    echo "VM suspended successfully."
}

# Function to resume a VM
resume_vm() {
    local vm_name="$1"
    
    if [ -z "$vm_name" ]; then
        echo "Usage: $0 resume <vm-name>"
        return 1
    fi
    
    if ! virsh domstate "$vm_name" | grep -q "paused"; then
        echo "VM '$vm_name' is not paused."
        return 1
    fi
    
    echo "Resuming VM '$vm_name'..."
    virsh resume "$vm_name"
    echo "VM resumed successfully."
}

# Function to create a snapshot
create_snapshot() {
    local vm_name="$1"
    local snapshot_name="$2"
    
    if [ -z "$vm_name" ] || [ -z "$snapshot_name" ]; then
        echo "Usage: $0 snapshot-create <vm-name> <snapshot-name>"
        return 1
    fi
    
    if ! virsh dominfo "$vm_name" >/dev/null 2>&1; then
        echo "VM '$vm_name' does not exist."
        return 1
    fi
    
    echo "Creating snapshot '$snapshot_name' for VM '$vm_name'..."
    virsh snapshot-create-as "$vm_name" "$snapshot_name" "Snapshot created by NextraOS"
    echo "Snapshot created successfully."
}

# Function to restore a snapshot
restore_snapshot() {
    local vm_name="$1"
    local snapshot_name="$2"
    
    if [ -z "$vm_name" ] || [ -z "$snapshot_name" ]; then
        echo "Usage: $0 snapshot-restore <vm-name> <snapshot-name>"
        return 1
    fi
    
    if ! virsh snapshot-info "$vm_name" "$snapshot_name" >/dev/null 2>&1; then
        echo "Snapshot '$snapshot_name' does not exist for VM '$vm_name'."
        return 1
    fi
    
    echo "Restoring snapshot '$snapshot_name' for VM '$vm_name'..."
    virsh snapshot-revert "$vm_name" "$snapshot_name"
    echo "Snapshot restored successfully."
}

# Function to list snapshots
list_snapshots() {
    local vm_name="$1"
    
    if [ -z "$vm_name" ]; then
        echo "Usage: $0 snapshot-list <vm-name>"
        return 1
    fi
    
    if ! virsh dominfo "$vm_name" >/dev/null 2>&1; then
        echo "VM '$vm_name' does not exist."
        return 1
    fi
    
    echo "Snapshots for VM '$vm_name':"
    virsh snapshot-list "$vm_name"
}

# Function to delete a snapshot
delete_snapshot() {
    local vm_name="$1"
    local snapshot_name="$2"
    
    if [ -z "$vm_name" ] || [ -z "$snapshot_name" ]; then
        echo "Usage: $0 snapshot-delete <vm-name> <snapshot-name>"
        return 1
    fi
    
    if ! virsh snapshot-info "$vm_name" "$snapshot_name" >/dev/null 2>&1; then
        echo "Snapshot '$snapshot_name' does not exist for VM '$vm_name'."
        return 1
    fi
    
    echo "Deleting snapshot '$snapshot_name' for VM '$vm_name'..."
    virsh snapshot-delete "$vm_name" "$snapshot_name"
    echo "Snapshot deleted successfully."
}

# Function to configure CPU pinning
configure_cpu_pinning() {
    local vm_name="$1"
    local cpu_list="$2"
    
    if [ -z "$vm_name" ] || [ -z "$cpu_list" ]; then
        echo "Usage: $0 cpu-pin <vm-name> <cpu-list>"
        echo "Example: $0 cpu-pin windows-vm 0,1,2,3"
        return 1
    fi
    
    if ! virsh dominfo "$vm_name" >/dev/null 2>&1; then
        echo "VM '$vm_name' does not exist."
        return 1
    fi
    
    echo "Configuring CPU pinning for VM '$vm_name'..."
    virsh vcpupin "$vm_name" --config --all "$cpu_list"
    echo "CPU pinning configured successfully."
}

# Function to configure memory balloon
configure_memory_balloon() {
    local vm_name="$1"
    local enabled="$2"
    
    if [ -z "$vm_name" ] || [ -z "$enabled" ]; then
        echo "Usage: $0 memory-balloon <vm-name> <true|false>"
        return 1
    fi
    
    if ! virsh dominfo "$vm_name" >/dev/null 2>&1; then
        echo "VM '$vm_name' does not exist."
        return 1
    fi
    
    echo "Configuring memory balloon for VM '$vm_name'..."
    if [ "$enabled" = "true" ]; then
        virsh attach-device "$vm_name" --config --live << 'EOF'
<domain>
  <memballoon model='virtio'/>
</domain>
EOF
    else
        virsh detach-device "$vm_name" --config --live << 'EOF'
<domain>
  <memballoon model='none'/>
</domain>
EOF
    fi
    echo "Memory balloon configured successfully."
}

# Function to enable headless mode
enable_headless() {
    local vm_name="$1"
    
    if [ -z "$vm_name" ]; then
        echo "Usage: $0 headless <vm-name>"
        return 1
    fi
    
    if ! virsh dominfo "$vm_name" >/dev/null 2>&1; then
        echo "VM '$vm_name' does not exist."
        return 1
    fi
    
    echo "Enabling headless mode for VM '$vm_name'..."
    virsh set-autostart "$vm_name" --disable
    echo "Headless mode enabled. VM will not start automatically."
}

# Function to list all VMs
list_vms() {
    echo "All VMs:"
    virsh list --all
}

# Function to show VM status
show_status() {
    local vm_name="$1"
    
    if [ -z "$vm_name" ]; then
        echo "Usage: $0 status <vm-name>"
        return 1
    fi
    
    echo "VM Status:"
    virsh dominfo "$vm_name"
}

# Function to show help
show_help() {
    echo "Usage: $0 {suspend|resume|snapshot-*|cpu-pin|memory-balloon|headless|list|status}"
    echo ""
    echo "Commands:"
    echo "  suspend <vm-name>              Suspend a VM"
    echo "  resume <vm-name>               Resume a suspended VM"
    echo "  snapshot-create <vm-name> <name>  Create a snapshot"
    echo "  snapshot-restore <vm-name> <name> Restore a snapshot"
    echo "  snapshot-list <vm-name>        List snapshots"
    echo "  snapshot-delete <vm-name> <name> Delete a snapshot"
    echo "  cpu-pin <vm-name> <cpu-list>   Configure CPU pinning"
    echo "  memory-balloon <vm-name> <true|false>  Configure memory balloon"
    echo "  headless <vm-name>             Enable headless mode"
    echo "  list                           List all VMs"
    echo "  status <vm-name>               Show VM status"
}

# Main
case "${1:-}" in
    suspend)
        suspend_vm "$2"
        ;;
    resume)
        resume_vm "$2"
        ;;
    snapshot-create)
        create_snapshot "$2" "$3"
        ;;
    snapshot-restore)
        restore_snapshot "$2" "$3"
        ;;
    snapshot-list)
        list_snapshots "$2"
        ;;
    snapshot-delete)
        delete_snapshot "$2" "$3"
        ;;
    cpu-pin)
        configure_cpu_pinning "$2" "$3"
        ;;
    memory-balloon)
        configure_memory_balloon "$2" "$3"
        ;;
    headless)
        enable_headless "$2"
        ;;
    list)
        list_vms
        ;;
    status)
        show_status "$2"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
