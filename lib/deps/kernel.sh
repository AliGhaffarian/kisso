#!/usr/bin/env sh

KERNEL_DEB_URL=${KERNEL_DEB_URL:-"https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-42-amd64_6.1.159-1_amd64.deb"}

install_kernel_modules() {
	mkdir -p lib
	TARGET=$(pwd)

	wget "${KERNEL_DEB_URL}" --no-clobber -O "${BINARIES_DIST}"/linux-image.deb

	tmp=$(mktemp -d kernel.XXXX)
	cd "${tmp}" || exit
	ar x "${BINARIES_DIST}"/linux-image.deb
	tar xf data.tar.xz

	cp -a lib/modules/6.1.0-42-amd64/modules.* "${TARGET}"/lib/
    modules=$(cat "${INITRD_DIST}"/usr/share/kernel-modules.lst)

	for mod in ${modules}; do
		find lib -type f -name "*$mod*.ko" -exec cp --parents {} "${TARGET}/" \;
	done

	cd ..
	rm -rf "${tmp}"
}

install_kernel() {
	TARGET=$(pwd)

	wget "${KERNEL_DEB_URL}" --no-clobber -O "${BINARIES_DIST}"/linux-image.deb

	tmp=$(mktemp -d kernel.XXXX)
	cd "${tmp}" || exit
	ar x "${BINARIES_DIST}"/linux-image.deb
	tar xf data.tar.xz

	cp boot/vmlinuz-6.1.0-42-amd64 "${TARGET}"/boot/vmlinuz

	cd ..
	rm -rf "${tmp}"
}
