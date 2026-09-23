#!/bin/bash
# macOS VM Management Script (legacy wrapper)
# Delegates to nextraos-vm which is the canonical VM manager.

set -e

case "${1:-}" in
    download-opencore)
        echo "OpenCore must be downloaded manually due to licensing."
        echo "Please download OpenCore from: https://github.com/acidanthera/OpenCorePkg/releases"
        echo "Extract the ISO to: /usr/share/nextraos/opencore"
        echo ""
        echo "Alternatively, use macOS-Simple-KVM:"
        echo "  git clone https://github.com/foxlet/macOS-Simple-KVM.git"
        echo "  cp macOS-Simple-KVM/OpenCore/OC_*.img /usr/share/nextraos/opencore/"
        ;;
    download-recovery|download-iso)
        exec nextraos-vm download-iso macos
        ;;
    create)
        exec nextraos-vm create macos
        ;;
    start)
        exec nextraos-vm start macos
        ;;
    stop)
        exec nextraos-vm stop macos
        ;;
    status)
        exec nextraos-vm status macos
        ;;
    connect)
        exec nextraos-vm connect macos
        ;;
    *)
        echo "Usage: $0 {download-opencore|download-recovery|create|start|stop|status|connect}"
        echo "This script is a compatibility wrapper. Prefer: nextraos-vm <action> macos"
        exit 1
        ;;
esac
