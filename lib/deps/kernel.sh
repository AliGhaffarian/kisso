#!/usr/bin/env sh

KERNEL_DEB_URL=${KERNEL_DEB_URL:-"https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-42-amd64_6.1.159-1_amd64.deb"}

# install_kernel_modules <dest_dir> [bin_cache_dir]
#
# install kernel modules on specified directory.
# dest_dir should contain ${dest_dir}"/usr/share/kernel-modules.lst
# file. This file have a list of required kernel modules for your
# linux. Modules will installed on lib/modules/6.1.0-42-amd64/
# Download required binary and cache them on specified directory.
#
# args:
# - dest_dir: target direcory to install kernel modules
# - bin_cache_dir (default=$BINARIES_DIST): download and cache binaries
#
# envs:
# - KERNEL_DEB_URL: modules will extracted form this debian package
# - BINARIES_DIST: default path for caching downloaded binaries
install_kernel_modules() {
	dest_dir=$1
	bin_cache_dir=${2:-$BINARIES_DIST}

	if [ -z "$dest_dir" ]; then
		echo "Error: dest_dir is required" >&2
		exit 1
	fi
	if [ -z "$bin_cache_dir" ]; then
		echo "Error: bin_cache_dir not set and BINARIES_DIST not defined" >&2
		exit 1
	fi

	wget "${KERNEL_DEB_URL}" --no-clobber -O "${bin_cache_dir}/linux-image.deb"

	tmp=$(mktemp -d kernel.XXXX)
	cd "${tmp}" || exit
	ar x "${bin_cache_dir}/linux-image.deb"
	tar xf data.tar.xz

	kmod_dir="${dest_dir}/lib/modules/6.1.0-42-amd64"
	mkdir -p "$kmod_dir"

	cp -a lib/modules/6.1.0-42-amd64/modules.* "$kmod_dir/"

	modules=$(cat "${dest_dir}/usr/share/kernel-modules.lst")

	for mod in ${modules}; do
		find lib -type f -name "*$mod*.ko" -exec cp --parents {} "${dest_dir}/" \;
	done

	cd ..
	rm -rf "${tmp}"
}

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

	cp boot/vmlinuz-6.1.0-42-amd64 "${dest_dir}/boot/vmlinuz"

	cd ..
	rm -rf "${tmp}"
}
