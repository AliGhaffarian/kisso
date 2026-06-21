#!/usr/bin/env bash

. dependencies.sh

BINARIES_DIST=$(pwd)/bins
ROOTFS_DIST=$(pwd)/build/rootfs
INITRD_DIST=$(pwd)/build/initrd
BUILD_DIR=$(pwd)/build

mkdir -p ${BUILD_DIR} ${BINARIES_DIST}
cp -r initrd rootfs ${BUILD_DIR}

cd $BUILD_DIR/initrd
install_busybox
install_kernel_modules
install_curl
install_gpgv
install_ca_certificates
install_keyrings
install_debootstrap
cd ..

cd $BUILD_DIR/rootfs
install_kernel
install_initramfs ${INITRD_DIST} ${ROOTFS_DIST}
cd ..

grub-mkrescue -o ministaller.iso ${ROOTFS_DIST}
