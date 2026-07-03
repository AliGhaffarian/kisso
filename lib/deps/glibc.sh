#!/usr/bin/env sh

GLIBC_DEB_URL=${GLIBC_DEB_URL:-"https://ftp.debian.org/debian/pool/main/g/glibc/libc6_2.41-12+deb13u3_amd64.deb"}

# install_glibc rootfs_dir
#
# download and extract the Debian glibc runtime package, then install the
# required shared libraries into the target root filesystem. Also create the
# dynamic linker symlink expected by dynamically linked executables.
install_glibc() {
	DIST=$1

	wget "$GLIBC_DEB_URL" --no-clobber -O "$BINARIES_DIST"/glibc.deb
	tmp=$(mktemp -d libc.XXXX)
	cd "${tmp}" || exit
	ar x "$BINARIES_DIST"/glibc.deb
	tar xf data.tar.xz

	mkdir -p "${DIST}"/lib64
	cp --parents -r usr/lib/x86_64-linux-gnu/*.* "$DIST"/
	cp --parents -r usr/lib64/* "$DIST"/
	ln -sfn /usr/lib64/ld-linux-x86-64.so.2  "$DIST/lib64/ld-linux-x86-64.so.2"
	cd ..
	rm -rf "${tmp}"
}
