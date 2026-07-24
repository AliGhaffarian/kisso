#!/usr/bin/env sh

SCRIPT_DIR=$(dirname "$0")

DISK_SIZE="4G"
DISK="${PWD}/build/minidebian.img"
ISO="${PWD}/debian-installer.iso"
DEBIAN_MIRROR=${DEBIAN_MIRROR:-"https://deb.debian.org/debian"}

./iso-installer.sh targets/debian-installer.lst

truncate "$DISK" -s $DISK_SIZE

expect -f "$SCRIPT_DIR"/install-debian.exp "$DISK" "$ISO" "$DEBIAN_MIRROR"
