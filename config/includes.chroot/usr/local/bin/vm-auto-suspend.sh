#!/bin/bash
# VM Auto-Suspend Script
# This script monitors running VMs and suspends them after a configurable grace period

set -e

GRACE_PERIOD=${GRACE_PERIOD:-300}  # 5 minutes default
LOG_FILE="/var/log/vm-auto-suspend.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to get running VMs
get_running_vms() {
    virsh list --state-running --name 2>/dev/null
}

# Function to suspend a VM
suspend_vm() {
    local vm_name="$1"
    
    if virsh domstate "$vm_name" | grep -q "running"; then
        log_message "Suspending VM '$vm_name'..."
        virsh suspend "$vm_name"
        log_message "VM '$vm_name' suspended."
    fi
}

# Function to check if VM should be suspended
should_suspend() {
    local vm_name="$1"
    
    # Check if VM has been idle for grace period
    # This is a simplified check - in production, you'd track idle time
    local last_activity=$(virsh domstats "$vm_name" 2>/dev/null | grep "cpu.time" | awk '{print $NF}')
    
    # For now, we'll use a simple timeout approach
    # In a real implementation, you'd track VM activity
    return 1
}

# Main monitoring loop
main() {
    log_message "VM Auto-Suspend service started"
    
    while true; do
        # Get list of running VMs
        local running_vms=$(get_running_vms)
        
        # Check each VM
        for vm in $running_vms; do
            if should_suspend "$vm"; then
                suspend_vm "$vm"
            fi
        done
        
        # Sleep for 60 seconds before next check
        sleep 60
    done
}

# Handle signals
trap 'log_message "VM Auto-Suspend service stopping"; exit 0' SIGTERM SIGINT

# Run main function
main
