#!/usr/bin/env sh

CDEBOOTSTRAP_STATIC_DEB_URL=${CDEBOOTSTRAP_STATIC_DEB_URL:-"https://ftp.debian.org/debian/pool/main/c/cdebootstrap/cdebootstrap-static_0.7.8+b38_amd64.deb"}

install_debootstrap() {
	wget "$CDEBOOTSTRAP_STATIC_DEB_URL" --no-clobber -O "$BINARIES_DIST"/cdebootstrap-static.deb
	tmp=$(mktemp -d debootstrap.XXXX)
	cd "${tmp}" || exit
	ar x "$BINARIES_DIST"/cdebootstrap-static.deb
	tar xf data.tar.xz

	cp --parents -r usr/ ../

	cd ..
	mv usr/bin/cdebootstrap-static usr/bin/cdebootstrap
	rm -rf "${tmp}"
}
