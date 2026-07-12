#!/usr/bin/env sh

export BINARIES_DIST="${PWD}/bins"
export BUILD_DIR="${PWD}/build"
export ROOTFS_DIST="${BUILD_DIR}/rootfs"
export INITRD_DIST="${BUILD_DIR}/initrd"
tools_path=./tools

USER_PACKAGES_CONFIG=$1
if [ ! -f "${USER_PACKAGES_CONFIG}" ]; then
    echo "$0 <CONFIG_FILE>"
    echo "$1 does not exists"
    exit 1
fi
package_installers=$(cat "${USER_PACKAGES_CONFIG}")

mkdir -p "${BUILD_DIR}" "${BINARIES_DIST}"
cp -r initrd rootfs "${BUILD_DIR}"

for installer in $package_installers; do
    "$tools_path/$installer".sh "$INITRD_DIST" "$BINARIES_DIST"
done

$tools_path/install-kernel.sh "$ROOTFS_DIST" "$BINARIES_DIST"
$tools_path/install-initrd.sh "$INITRD_DIST" "$ROOTFS_DIST"

iso_name=$(basename "${USER_PACKAGES_CONFIG}" | sed 's/.lst/.iso/g')
grub-mkrescue -o "$iso_name" "$ROOTFS_DIST"
