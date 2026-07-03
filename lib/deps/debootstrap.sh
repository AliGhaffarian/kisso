CDEBOOTSTRAP_STATIC_DEB_URL=${CDEBOOTSTRAP_STATIC_DEB_URL:-"https://ftp.debian.org/debian/pool/main/c/cdebootstrap/cdebootstrap-static_0.7.8+b38_amd64.deb"}

install_debootstrap() {
    wget ${CDEBOOTSTRAP_STATIC_DEB_URL} --no-clobber -O ${BINARIES_DIST}/cdebootstrap-static.deb
    mkdir -p cdebootstrap-static
    cd cdebootstrap-static
    ar x ${BINARIES_DIST}/cdebootstrap-static.deb
    tar xf data.tar.xz

    cp --parents -r usr/ ../

    cd ..
    mv usr/bin/cdebootstrap-static usr/bin/cdebootstrap
    rm -rf cdebootstrap-static
}
