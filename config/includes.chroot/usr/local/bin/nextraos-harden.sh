#!/bin/bash
# NextraOS Production Hardening Script

set -e

LOG_FILE="/var/log/nextraos-hardening.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Function to configure firewall
configure_firewall() {
    log_message "Configuring firewall..."
    
    # Install ufw if not present
    if ! command -v ufw &> /dev/null; then
        apt-get install -y ufw
    fi
    
    # Configure basic firewall rules
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 5900:5999/tcp  # VNC
    ufw allow 5900:5999/udp  # VNC
    
    # Enable firewall
    ufw --force enable
    
    log_message "Firewall configured successfully."
}

# Function to configure automatic updates
configure_automatic_updates() {
    log_message "Configuring automatic updates..."
    
    # Install unattended-upgrades
    apt-get install -y unattended-upgrades
    
    # Configure automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    
    log_message "Automatic updates configured successfully."
}

# Function to configure logging
configure_logging() {
    log_message "Configuring logging..."
    
    # Install rsyslog if not present
    if ! command -v rsyslogd &> /dev/null; then
        apt-get install -y rsyslog
    fi
    
    # Configure log rotation
    cat > /etc/logrotate.d/nextraos << 'EOF'
/var/log/nextraos/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate 2>/dev/null || true
    endscript
}
EOF
    
    # Enable rsyslog
    systemctl enable rsyslog
    systemctl start rsyslog
    
    log_message "Logging configured successfully."
}

# Function to configure diagnostics
configure_diagnostics() {
    log_message "Configuring diagnostics..."
    
    # Install diagnostic tools
    apt-get install -y \
        htop \
        iotop \
        iftop \
        nethogs \
        sysstat \
        dstat \
        strace \
        ltrace \
        tcpdump \
        wireshark-common
    
    # Create diagnostic script
    cat > /usr/local/bin/nextraos-diagnose << 'SCRIPT'
#!/bin/bash
echo "=== NextraOS Diagnostics ==="
echo ""
echo "=== System Information ==="
uname -a
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== CPU Usage ==="
top -bn1 | head -20
echo ""
echo "=== Network Connections ==="
ss -tuln
echo ""
echo "=== Running Services ==="
systemctl list-units --type=service --state=running
echo ""
echo "=== VM Status ==="
virsh list --all 2>/dev/null || echo "No VMs found"
echo ""
echo "=== Log Files ==="
ls -la /var/log/nextraos/ 2>/dev/null || echo "No log files found"
SCRIPT
    
    chmod +x /usr/local/bin/nextraos-diagnose
    
    log_message "Diagnostics configured successfully."
}

# Function to configure resource management
configure_resource_management() {
    log_message "Configuring resource management..."
    
    # Install cgroup tools
    apt-get install -y cgroup-tools
    
    # Create resource management script
    cat > /usr/local/bin/nextraos-resource-manager << 'SCRIPT'
#!/bin/bash
# NextraOS Resource Manager

set -e

# Function to set CPU limits
set_cpu_limit() {
    local process="$1"
    local limit="$2"
    
    if [ -z "$process" ] || [ -z "$limit" ]; then
        echo "Usage: $0 cpu-limit <process> <limit>"
        return 1
    fi
    
    cgcreate -g cpu:/$process
    echo $limit > /sys/fs/cgroup/cpu/$process/cpu.cfs_quota_us
    echo "CPU limit set for $process: $limit"
}

# Function to set memory limits
set_memory_limit() {
    local process="$1"
    local limit="$2"
    
    if [ -z "$process" ] || [ -z "$limit" ]; then
        echo "Usage: $0 memory-limit <process> <limit>"
        return 1
    fi
    
    cgcreate -g memory:/$process
    echo $limit > /sys/fs/cgroup/memory/$process/memory.limit_in_bytes
    echo "Memory limit set for $process: $limit"
}

# Function to show resource usage
show_resources() {
    echo "=== CPU Usage ==="
    top -bn1 | head -20
    echo ""
    echo "=== Memory Usage ==="
    free -h
    echo ""
    echo "=== Disk Usage ==="
    df -h
    echo ""
    echo "=== CGroup Status ==="
    lscgroup
}

# Main
case "${1:-}" in
    cpu-limit)
        set_cpu_limit "$2" "$3"
        ;;
    memory-limit)
        set_memory_limit "$2" "$3"
        ;;
    status)
        show_resources
        ;;
    *)
        echo "Usage: $0 {cpu-limit|memory-limit|status}"
        exit 1
        ;;
esac
SCRIPT
    
    chmod +x /usr/local/bin/nextraos-resource-manager
    
    log_message "Resource management configured successfully."
}

# Function to configure installer reliability
configure_installer_reliability() {
    log_message "Configuring installer reliability..."
    
    # Create installer check script
    cat > /usr/local/bin/nextraos-installer-check << 'SCRIPT'
#!/bin/bash
# NextraOS Installer Reliability Check

set -e

echo "=== NextraOS Installer Check ==="
echo ""

# Check disk space
echo "=== Disk Space Check ==="
df -h / | tail -1
echo ""

# Check network connectivity
echo "=== Network Connectivity Check ==="
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "Network: OK"
else
    echo "Network: FAILED"
fi
echo ""

# Check required packages
echo "=== Required Packages Check ==="
for pkg in calamares live-build; do
    if dpkg -l | grep -q "$pkg"; then
        echo "$pkg: INSTALLED"
    else
        echo "$pkg: NOT INSTALLED"
    fi
done
echo ""

# Check ISO integrity
echo "=== ISO Integrity Check ==="
if [ -f "/home/user/nextraos.iso" ]; then
    md5sum /home/user/nextraos.iso
else
    echo "ISO file not found"
fi
echo ""

echo "=== Check Complete ==="
SCRIPT
    
    chmod +x /usr/local/bin/nextraos-installer-check
    
    log_message "Installer reliability configured successfully."
}

# Main function
main() {
    check_root
    
    log_message "Starting NextraOS production hardening..."
    
    configure_firewall
    configure_automatic_updates
    configure_logging
    configure_diagnostics
    configure_resource_management
    configure_installer_reliability
    
    log_message "NextraOS production hardening complete."
    echo ""
    echo "Production hardening complete!"
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@"
