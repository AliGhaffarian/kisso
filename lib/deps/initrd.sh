#!/usr/bin/env sh

# install_initramfs initramfs_dir rootfs_dir
#
# archive initramfs path and build initrd, save to ${ROOTFS_DIR}/boot/initramfs
install_initramfs() {
	INITRD_DIR=$1
	ROOTFS_DIR=$2

	cd "$INITRD_DIR" || exit
	find . | cpio -ov --format=newc | gzip -9 >"$ROOTFS_DIR"/boot/initramfs
	cd - || exit
}
