BUSYBOX_URL=${BUSYBOX_URL:-"https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64"}

install_busybox() {
    mkdir -p bin

    wget ${BUSYBOX_URL} --no-clobber -O ${BINARIES_DIST}/busybox
    install -m 755 ${BINARIES_DIST}/busybox bin
}
