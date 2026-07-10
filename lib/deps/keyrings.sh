#!/usr/bin/env sh

KEYRINGS_DEB_URL=${KEYRINGS_DEB_URL:-"https://deb.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2025.1_all.deb"}

# install_keyrings [dest_dir] [bin_cache_dir]
#
# download and extract the Debian archive keyring package, then install the
# keyring files into ${dest_dir}/usr/share/keyrings/.
#
# args:
# - dest_dir (default=current dir): target directory to install keyrings
# - bin_cache_dir (default=$BINARIES_DIST): download and cache binaries
#
# envs:
# - KEYRINGS_DEB_URL: keyrings will be extracted from this Debian package
# - BINARIES_DIST: default path for caching downloaded binaries
install_keyrings() {
	dest_dir=${1:-$PWD}
	bin_cache_dir=${2:-$BINARIES_DIST}

	wget "$KEYRINGS_DEB_URL" --no-clobber -O "$bin_cache_dir/debian-archive-keyring.deb"
	tmp=$(mktemp -d keyring.XXXX)
	cd "$tmp" || exit
	ar x "$bin_cache_dir/debian-archive-keyring.deb"
	tar xf data.tar.xz

	# Copy the entire usr/ tree into dest_dir
	cp -a usr "$dest_dir/"

	cd ..
	rm -rf "$tmp"
}