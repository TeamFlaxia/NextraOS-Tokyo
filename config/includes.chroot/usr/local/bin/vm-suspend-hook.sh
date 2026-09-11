#!/bin/bash
# System Suspend Hook for VMs
# This script handles VMs when the system is suspended

set -e

ACTION="$1"
LOG_FILE="/var/log/vm-suspend.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to suspend all running VMs
suspend_all_vms() {
    log_message "Suspending all running VMs..."
    
    local running_vms=$(virsh list --state-running --name 2>/dev/null)
    
    for vm in $running_vms; do
        log_message "Suspending VM '$vm'..."
        virsh suspend "$vm"
        log_message "VM '$vm' suspended."
    done
    
    log_message "All VMs suspended."
}

# Function to resume all suspended VMs
resume_all_vms() {
    log_message "Resuming all suspended VMs..."
    
    local paused_vms=$(virsh list --state-paused --name 2>/dev/null)
    
    for vm in $paused_vms; do
        log_message "Resuming VM '$vm'..."
        virsh resume "$vm"
        log_message "VM '$vm' resumed."
    done
    
    log_message "All VMs resumed."
}

# Main
case "$ACTION" in
    suspend)
        suspend_all_vms
        ;;
    resume)
        resume_all_vms
        ;;
    *)
        echo "Usage: $0 {suspend|resume}"
        exit 1
        ;;
esac
