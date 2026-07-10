#!/usr/bin/env sh

BUSYBOX_URL=${BUSYBOX_URL:-"https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64"}

# install_busybox [dest_dir] [bin_cache_dir]
#
# download and install the BusyBox static binary into the target root filesystem.
# The binary is placed in ${dest_dir}/bin/busybox.
#
# args:
# - dest_dir (default=current dir): target directory to install busybox
# - bin_cache_dir (default=$BINARIES_DIST): download and cache binaries
#
# envs:
# - BUSYBOX_URL: URL of the static BusyBox binary
# - BINARIES_DIST: default path for caching downloaded binaries
install_busybox() {
	dest_dir=${1:-$PWD}
	bin_cache_dir=${2:-$BINARIES_DIST}

	mkdir -p "$dest_dir/bin"

	wget "$BUSYBOX_URL" --no-clobber -O "$bin_cache_dir/busybox"
	install -m 755 "$bin_cache_dir/busybox" "$dest_dir/bin/busybox"
}
