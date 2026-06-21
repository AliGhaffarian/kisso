#!/usr/bin/env bash

BUSYBOX_URL="https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64"
CURL_URL="https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64"
KERNEL_DEB_URL="https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-42-amd64_6.1.159-1_amd64.deb"
KEYRINGS_DEB_URL="https://deb.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2025.1_all.deb"
CDEBOOTSTRAP_STATIC_DEB_URL="https://ftp.debian.org/debian/pool/main/c/cdebootstrap/cdebootstrap-static_0.7.8+b38_amd64.deb"
CERTIFICATE_DEB_URL="https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20260601_all.deb"
GPGV_DEB_URL="https://ftp.debian.org/debian/pool/main/g/gnupg2/gpgv-static_2.4.7-21+deb13u1+b4_amd64.deb"

function install_busybox() {
    mkdir -p bin

    wget ${BUSYBOX_URL} --no-clobber -O ${BINARIES_DIST}/busybox
    install -m 755 ${BINARIES_DIST}/busybox bin
}

function install_kernel_modules() {
    mkdir -p lib
    TARGET=$(pwd)

    wget ${KERNEL_DEB_URL} --no-clobber -O ${BINARIES_DIST}/linux-image.deb

    mkdir -p linux-image
    cd linux-image
    ar x ${BINARIES_DIST}/linux-image.deb
    tar xf data.tar.xz

    cp -a lib/modules/6.1.0-42-amd64/modules.* ${TARGET}/lib/
    for mod in $(cat ${INITRD_DIST}/usr/share/kernel-modules.lst); do
        find lib -type f -name "*$mod*.ko" -exec cp --parents {} "${TARGET}/" \;
    done

    cd ..
    rm -rf linux-image
}

function install_kernel() {
    TARGET=$(pwd)

    wget ${KERNEL_DEB_URL} --no-clobber -O ${BINARIES_DIST}/linux-image.deb

    mkdir -p linux-image
    cd linux-image
    ar x ${BINARIES_DIST}/linux-image.deb
    tar xf data.tar.xz

    cp boot/vmlinuz-6.1.0-42-amd64 ${TARGET}/boot/vmlinuz
    
    cd ..
    rm -rf linux-image
}

function install_curl() {
    mkdir -p bin

    wget ${CURL_URL} --no-clobber -O ${BINARIES_DIST}/curl
    install -m 755 ${BINARIES_DIST}/curl bin
}

function install_gpgv() {
    mkdir -p bin
    TARGET=$(pwd)

    wget ${GPGV_DEB_URL} --no-clobber -O ${BINARIES_DIST}/gpgv.deb
    mkdir -p gpgv
    cd gpgv
    ar x ${BINARIES_DIST}/gpgv.deb
    tar xf data.tar.xz

    cp usr/bin/gpgv-static ${TARGET}/bin/gpgv

    cd ..
    rm -rf gpgv
}

function install_ca_certificates() {
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

function install_keyrings() {
    wget ${KEYRINGS_DEB_URL} --no-clobber -O ${BINARIES_DIST}/debian-archive-keyring.deb
    mkdir -p keyring
    cd keyring
    ar x ${BINARIES_DIST}/debian-archive-keyring.deb
    tar xf data.tar.xz

    cp --parents -r usr/ ../

    cd ..
    rm -rf keyring
}

function install_debootstrap() {
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

# install_initramfs initramfs_dir rootfs_dir
# 
# archive initramfs path and build initrd, save to ${ROOTFS_DIR}/boot/initramfs
function install_initramfs() {
    INITRD_DIR=$1
    ROOTFS_DIR=$2

    cd ${INITRD_DIR}
    find . | cpio -ov --format=newc | gzip -9 >${ROOTFS_DIR}/boot/initramfs
    cd -
}
