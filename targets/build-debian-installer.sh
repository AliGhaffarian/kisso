#!/usr/bin/env sh

. ./lib/deps/busybox.sh
. ./lib/deps/certs.sh
. ./lib/deps/curl.sh
. ./lib/deps/debootstrap.sh
. ./lib/deps/glibc.sh
. ./lib/deps/gpgv.sh
. ./lib/deps/initrd.sh
. ./lib/deps/kernel.sh
. ./lib/deps/keyrings.sh

export BINARIES_DIST="${PWD}/bins"
export BUILD_DIR="${PWD}/build"
export ROOTFS_DIST="${BUILD_DIR}/rootfs"
export INITRD_DIST="${BUILD_DIR}/initrd"

mkdir -p "${BUILD_DIR}" "${BINARIES_DIST}"
cp -r initrd rootfs "${BUILD_DIR}"

cd "${BUILD_DIR}" || exit
install_busybox "$INITRD_DIST" "$BINARIES_DIST"
install_kernel_modules "$INITRD_DIST" "$BINARIES_DIST"
install_curl "$INITRD_DIST" "$BINARIES_DIST"
install_gpgv "$INITRD_DIST" "$BINARIES_DIST"
install_ca_certificates "$INITRD_DIST" "$BINARIES_DIST"
install_keyrings "$INITRD_DIST" "$BINARIES_DIST"
install_debootstrap "$INITRD_DIST" "$BINARIES_DIST"

install_kernel "$ROOTFS_DIST" "$BINARIES_DIST"
install_initramfs "$INITRD_DIST" "$ROOTFS_DIST"

grub-mkrescue -o ministaller.iso "$ROOTFS_DIST"
