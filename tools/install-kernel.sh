#!/usr/bin/env sh

KERNEL_DEB_URL=${KERNEL_DEB_URL:-"https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-47-amd64_6.1.170-3_amd64.deb"}

# install_kernel [dest_dir] [bin_cache_dir]
#
# install vmlinuz kernel binary on specified directory on
# ${dest_dir}/boot/vmlinuz. Download and cache kernel binary
# on bin_cache_dir path for later runs of script.
#
# args:
# - dest_dir (default=current dir): target direcory to install kernel modules
# - bin_cache_dir (default=$BINARIES_DIST): download and cache binaries
#
# envs:
# - KERNEL_DEB_URL: kernel binary will extracted form this debian package
# - BINARIES_DIST: default path for caching downloaded binaries
install_kernel() {
	dest_dir=$1
	bin_cache_dir=$2

	if [ -z "$bin_cache_dir" ]; then
		echo "Error: bin_cache_dir not set and BINARIES_DIST not defined" >&2
		exit 1
	fi

	wget "${KERNEL_DEB_URL}" --no-clobber -O "${bin_cache_dir}/linux-image.deb"

	mkdir -p "${dest_dir}/boot"

	tmp=$(mktemp -d kernel.XXXX)
	cd "${tmp}" || exit
	ar x "${bin_cache_dir}/linux-image.deb"
	tar xf data.tar.xz

	cp boot/vmlinuz-*-amd64 "${dest_dir}/boot/vmlinuz"

	cd ..
	rm -rf "${tmp}"
}

install_kernel "$@"
