#!/usr/bin/env sh

KEYRINGS_DEB_URL=${KEYRINGS_DEB_URL:-"https://deb.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2025.1_all.deb"}

install_keyrings() {
	wget "$KEYRINGS_DEB_URL" --no-clobber -O "$BINARIES_DIST"/debian-archive-keyring.deb
	tmp=$(mktemp -d keyring.XXXX)
	cd "${tmp}" || exit
	ar x "$BINARIES_DIST"/debian-archive-keyring.deb
	tar xf data.tar.xz

	cp --parents -r usr/ ../

	cd ..
	rm -rf "${tmp}"
}
