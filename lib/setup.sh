#!/usr/bin/env sh

# Shared environment variables for build
export BINARIES_DIST="${PWD}"/bins
export BUILD_DIR="${PWD}"/build
export ROOTFS_DIST="${BUILD_DIR}"/rootfs
export INITRD_DIST="${BUILD_DIR}"/initrd

. ./lib/deps/busybox.sh
. ./lib/deps/certs.sh
. ./lib/deps/curl.sh
. ./lib/deps/debootstrap.sh
. ./lib/deps/glibc.sh
. ./lib/deps/gpgv.sh
. ./lib/deps/initrd.sh
. ./lib/deps/kernel.sh
. ./lib/deps/keyrings.sh

# Create build directory in currect dir and copy initrd/rootfs template
# for new build.
create_build_dir() {
	mkdir -p "${BUILD_DIR}" "${BINARIES_DIST}"
	cp -r initrd rootfs "${BUILD_DIR}"
}
