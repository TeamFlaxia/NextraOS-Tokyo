#!/bin/bash
# Windows VM Management Script (legacy wrapper)
# Delegates to nextraos-vm which is the canonical VM manager.

set -e

case "${1:-status}" in
    start)
        exec nextraos-vm start windows
        ;;
    stop)
        exec nextraos-vm stop windows
        ;;
    status)
        exec nextraos-vm status windows
        ;;
    connect)
        exec nextraos-vm connect windows
        ;;
    *)
        echo "Usage: $0 {start|stop|status|connect}"
        echo "This script is a compatibility wrapper. Prefer: nextraos-vm <action> windows"
        exit 1
        ;;
esac
