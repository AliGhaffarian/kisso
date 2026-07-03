#!/usr/bin/env sh

GPGV_DEB_URL=${GPGV_DEB_URL:-"https://ftp.debian.org/debian/pool/main/g/gnupg2/gpgv-static_2.4.7-21+deb13u1+b4_amd64.deb"}

install_gpgv() {
	mkdir -p bin
	TARGET=$PWD

	wget "$GPGV_DEB_URL" --no-clobber -O "$BINARIES_DIST"/gpgv.deb
	mkdir -p gpgv
	cd gpgv || exit
	ar x "$BINARIES_DIST"/gpgv.deb
	tar xf data.tar.xz

	cp usr/bin/gpgv-static "$TARGET"/bin/gpgv

	cd ..
	rm -rf gpgv
}
