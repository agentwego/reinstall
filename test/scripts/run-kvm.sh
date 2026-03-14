#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEST_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

config=${CONFIG:-$TEST_DIR/kvm/talos.env}
common_config="$TEST_DIR/kvm/common.env"
local_config="${config%.env}.local.env"

[ -f "$common_config" ] || { echo "Missing $common_config" >&2; exit 1; }
[ -f "$config" ] || { echo "Missing $config" >&2; exit 1; }

set -a
. "$common_config"
. "$config"
if [ -f "$local_config" ]; then
    . "$local_config"
fi
set +a

vm_name=${VM_NAME:-vm}
qemu_bin=${QEMU_BIN:-qemu-system-x86_64}
qemu_img_bin=${QEMU_IMG_BIN:-qemu-img}
machine=${MACHINE:-q35}
cpu=${CPU:-host}
memory=${MEMORY:-2048}
smp=${SMP:-2}
disk_size=${DISK_SIZE:-20G}
disk_image=${DISK_IMAGE:-$TEST_DIR/state/$vm_name.qcow2}
serial_mode=${SERIAL_MODE:-stdio}
graphics=${GRAPHICS:-gtk}
network=${NETWORK:-user}
enable_kvm=${ENABLE_KVM:-1}
artifacts_dir="$TEST_DIR/artifacts"
state_dir="$TEST_DIR/state"
serial_log=${SERIAL_LOG:-$artifacts_dir/$vm_name.serial.log}

mkdir -p "$artifacts_dir" "$state_dir"

if [ ! -f "$disk_image" ]; then
    if [ -n "${BASE_IMAGE:-}" ]; then
        "$qemu_img_bin" create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$disk_image"
    elif [ -n "${BOOT_ISO:-}" ]; then
        "$qemu_img_bin" create -f qcow2 "$disk_image" "$disk_size"
    else
        echo "Set BASE_IMAGE, BOOT_ISO, or DISK_IMAGE before launching QEMU." >&2
        exit 1
    fi
fi

netdev_arg="$network,id=net0"
if [ -n "${SSH_FORWARD:-}" ] && [ "$network" = user ]; then
    netdev_arg="user,id=net0,hostfwd=tcp::${SSH_FORWARD}-:22"
fi

args=(
    -name "$vm_name"
    -machine "$machine"
    -cpu "$cpu"
    -m "$memory"
    -smp "$smp"
    -drive "if=virtio,format=qcow2,file=$disk_image"
    -netdev "$netdev_arg"
    -device virtio-net-pci,netdev=net0
)

if [ "$enable_kvm" = 1 ] && [ -e /dev/kvm ]; then
    args+=(-enable-kvm)
elif [ "$enable_kvm" = 1 ]; then
    echo "/dev/kvm is not available, continuing without -enable-kvm." >&2
fi

if [ -n "${BOOT_ISO:-}" ]; then
    args+=(-cdrom "$BOOT_ISO")
fi

if [ -n "${CLOUD_INIT_ISO:-}" ]; then
    args+=(-drive "if=virtio,media=cdrom,readonly=on,file=$CLOUD_INIT_ISO")
fi

case "$serial_mode" in
stdio)
    args+=(-serial mon:stdio)
    ;;
file)
    args+=(-serial "file:$serial_log")
    ;;
none)
    ;;
*)
    echo "Unsupported SERIAL_MODE: $serial_mode" >&2
    exit 1
    ;;
esac

case "$graphics" in
gtk | sdl | cocoa)
    args+=(-display "$graphics")
    ;;
headless)
    args+=(-display none)
    ;;
*)
    echo "Unsupported GRAPHICS mode: $graphics" >&2
    exit 1
    ;;
esac

if [ -n "${EXTRA_ARGS:-}" ]; then
    # shellcheck disable=SC2206
    extra_args=($EXTRA_ARGS)
    args+=("${extra_args[@]}")
fi

exec "$qemu_bin" "${args[@]}"
