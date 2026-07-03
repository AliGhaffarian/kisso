#!/usr/bin/env sh

# Shared environment variables for build
export BINARIES_DIST="${PWD}"/bins
export BUILD_DIR="${PWD}"/build
export ROOTFS_DIST="${BUILD_DIR}"/rootfs
export INITRD_DIST="${BUILD_DIR}"/initrd

# Source all dependency modules.
#
# SC1090 is disabled because the sourced files are discovered dynamically
# via glob expansion. ShellCheck performs static analysis and cannot resolve
# the value of "$dep" at lint time, even though it is guaranteed to be one of
# the existing files matching ./lib/deps/*.sh at runtime.
#
# shellcheck disable=SC1090
for dep in ./lib/deps/*.sh; do
    [ -e "$dep" ] || continue
    . "$dep"
done

# Create build directory in currect dir and copy initrd/rootfs template
# for new build.
create_build_dir() {
	mkdir -p "${BUILD_DIR}" "${BINARIES_DIST}"
	cp -r initrd rootfs "${BUILD_DIR}"
}
