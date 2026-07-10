#!/usr/bin/env sh

CERTIFICATE_DEB_URL=${CERTIFICATE_DEB_URL:-"https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20260601_all.deb"}

# install_ca_certificates [dest_dir] [bin_cache_dir]
#
# download and extract the Debian ca-certificates package, then concatenate
# all Mozilla CA certificates into a single PEM file at
# ${dest_dir}/etc/ssl/certs/ca-certificates.crt.
#
# args:
# - dest_dir (default=current dir): target directory to install certificates
# - bin_cache_dir (default=$BINARIES_DIST): download and cache binaries
#
# envs:
# - CERTIFICATE_DEB_URL: certificates will be extracted from this Debian package
# - BINARIES_DIST: default path for caching downloaded binaries
install_ca_certificates() {
	dest_dir=${1:-$PWD}
	bin_cache_dir=${2:-$BINARIES_DIST}

	mkdir -p "$dest_dir/etc/ssl/certs"

	wget "$CERTIFICATE_DEB_URL" --no-clobber -O "$bin_cache_dir/certificates.deb"
	tmp=$(mktemp -d certs.XXXX)
	cd "$tmp" || exit
	ar x "$bin_cache_dir/certificates.deb"
	tar xf data.tar.xz

	cat usr/share/ca-certificates/mozilla/*.crt > "$dest_dir/etc/ssl/certs/ca-certificates.crt"

	cd ..
	rm -rf "$tmp"
}