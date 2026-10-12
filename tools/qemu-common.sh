# Shared QEMU accelerator selection; source from the runner scripts.
KVM_DEVICE=${NEXTRAOS_QEMU_KVM_DEVICE:-/dev/kvm}
if [ -r "$KVM_DEVICE" ] && [ -w "$KVM_DEVICE" ]; then
    NEXTRAOS_QEMU_ACCEL=kvm
    NEXTRAOS_QEMU_CPU=host
else
    NEXTRAOS_QEMU_ACCEL=tcg
    NEXTRAOS_QEMU_CPU=max
    echo "WARNING: $KVM_DEVICE is not accessible; using slow TCG acceleration." >&2
fi
NEXTRAOS_QEMU_GL=${NEXTRAOS_QEMU_GL:-1}
NEXTRAOS_QEMU_DISPLAY=${NEXTRAOS_QEMU_DISPLAY:-sdl}

# gtk-std is a software-only VGA diagnostic; it does not validate Niri rendering.
nextraos_qemu() {
    case "$NEXTRAOS_QEMU_DISPLAY" in
        none) set -- "$@" -device virtio-vga -display none ;;
        gtk)
            case "$NEXTRAOS_QEMU_GL" in
                1) set -- "$@" -device virtio-vga-gl -display gtk,gl=on ;;
                0) set -- "$@" -device virtio-vga -display gtk,gl=off ;;
                *) echo "ERROR: Set NEXTRAOS_QEMU_GL to 1 or 0." >&2; return 1 ;;
            esac
            ;;
        gtk-std) set -- "$@" -vga std -display gtk,gl=off ;;
        sdl)
            case "$NEXTRAOS_QEMU_GL" in
                1) set -- "$@" -device virtio-vga-gl -display sdl,gl=on ;;
                0) set -- "$@" -device virtio-vga -display sdl,gl=off ;;
                *) echo "ERROR: Set NEXTRAOS_QEMU_GL to 1 or 0." >&2; return 1 ;;
            esac
            ;;
        *) echo "ERROR: Set NEXTRAOS_QEMU_DISPLAY to sdl, gtk, gtk-std, or none." >&2; return 1 ;;
    esac
    case "$NEXTRAOS_QEMU_ACCEL" in
        kvm) qemu-system-x86_64 -enable-kvm -cpu "$NEXTRAOS_QEMU_CPU" "$@" ;;
        tcg) qemu-system-x86_64 -accel tcg,thread=multi -cpu "$NEXTRAOS_QEMU_CPU" "$@" ;;
        *) echo "ERROR: Unknown QEMU accelerator mode: $NEXTRAOS_QEMU_ACCEL" >&2; return 1 ;;
    esac
}

# QEMU writes UEFI variables; isolate each run from the packaged template.
nextraos_create_ovmf_vars_copy() {
    OVMF_TMP_ROOT=${TMPDIR:-/tmp}
    OVMF_TMP_ROOT=$(CDPATH= cd -P -- "$OVMF_TMP_ROOT" && pwd) || return 1
    OVMF_VARS_COPY=$(mktemp "$OVMF_TMP_ROOT/nextraos-ovmf-vars.XXXXXX") || return 1
    case "$OVMF_VARS_COPY" in
        "$OVMF_TMP_ROOT"/nextraos-ovmf-vars.*) ;;
        *) echo "ERROR: Unexpected OVMF variable-store path: $OVMF_VARS_COPY" >&2; return 1 ;;
    esac
    if ! cp -- "$1" "$OVMF_VARS_COPY"; then
        rm -f -- "$OVMF_VARS_COPY"
        return 1
    fi
}

nextraos_remove_ovmf_vars_copy() {
    [ -n "${OVMF_VARS_COPY:-}" ] || return 0
    case "$OVMF_VARS_COPY" in
        "${OVMF_TMP_ROOT:?}"/nextraos-ovmf-vars.*) rm -f -- "$OVMF_VARS_COPY" ;;
        *) echo "ERROR: Refusing to remove unexpected OVMF variable-store path: $OVMF_VARS_COPY" >&2; return 1 ;;
    esac
}
