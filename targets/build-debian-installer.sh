#!/usr/bin/env sh

. ./lib/setup.sh

create_build_dir

cd "$BUILD_DIR"/initrd || exit
install_busybox
install_kernel_modules
install_curl
install_gpgv
install_ca_certificates
install_keyrings
install_debootstrap
cd ..

cd "$BUILD_DIR"/rootfs || exit
install_kernel
install_initramfs "$INITRD_DIST" "$ROOTFS_DIST"
cd ..

grub-mkrescue -o ministaller.iso "$ROOTFS_DIST"
