CERTIFICATE_DEB_URL=${CERTIFICATE_DEB_URL:-"https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20260601_all.deb"}

install_ca_certificates() {
    mkdir -p etc/ssl/certs
    TARGET=$(pwd)

    wget ${CERTIFICATE_DEB_URL} --no-clobber -O ${BINARIES_DIST}/certificates.deb
    mkdir -p certs
    cd certs
    ar x ${BINARIES_DIST}/certificates.deb
    tar xf data.tar.xz

    cat usr/share/ca-certificates/mozilla/*.crt > ${TARGET}/etc/ssl/certs/ca-certificates.crt

    cd ..
    rm -rf certs
}
