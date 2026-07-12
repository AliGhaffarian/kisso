#!/usr/bin/env sh

# install_initramfs <initrd_dir> <rootfs_dir>
#
# archive initramfs path and build initrd, save to ${rootfs_dir}/boot/initramfs
#
# args:
# - initrd_dir: initrd directory for saving result
# - rootfs_dir: rootfs dir to cd and compress everything
install_initramfs() {
	initrd_dir=$1
	rootfs_dir=$2

	cd "$initrd_dir" || exit
	find . | cpio -ov --format=newc | gzip -9 >"$rootfs_dir"/boot/initramfs
	cd - || exit
}

install_initramfs "$@"
