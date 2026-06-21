#!/usr/bin/env bash

BUSYBOX_URL="https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64"
CURL_URL="https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64"
KERNEL_DEB_URL="https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-42-amd64_6.1.159-1_amd64.deb"
KEYRINGS_DEB_URL="https://deb.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2025.1_all.deb"
CDEBOOTSTRAP_STATIC_DEB_URL="https://ftp.debian.org/debian/pool/main/c/cdebootstrap/cdebootstrap-static_0.7.8+b38_amd64.deb"
CERTIFICATE_DEB_URL="https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20260601_all.deb"
GPGV_DEB_URL="https://ftp.debian.org/debian/pool/main/g/gnupg2/gpgv-static_2.4.7-21+deb13u1+b4_amd64.deb"

KERNEL_MODULES=(
    jbd2 crc16 mbcache ext4
    virtio virtio_ring failover net_failover virtio_net
    virtio_pci_modern_dev virtio_pci_legacy_dev virtio_pci
    virtio_blk crc32 crc32c
)

mkdir -p /tmp/mininstaller
cd /tmp/mininstaller

mkdir -p deps
cd deps

# Download busybox
wget ${BUSYBOX_URL} --no-clobber -O busybox
chmod +x busybox

# Download linux kernel
wget ${KERNEL_DEB_URL} --no-clobber -O linux-image.deb
mkdir -p linux-image kmods
cd linux-image
ar x ../linux-image.deb
tar xf data.tar.xz
cp boot/vmlinuz-6.1.0-42-amd64 ../vmlinuz

cp --parents lib/modules/6.1.0-42-amd64/modules.* ../kmods
for mod in ${KERNEL_MODULES[@]}; do
    find lib -name "*$mod*.ko" -exec cp --parents -r {} ../kmods \;
done

depmod -b ../kmods 6.1.0-42-amd64
cd ..
rm -rf linux-image

# Download curl
wget ${CURL_URL} --no-clobber -O curl
chmod +x curl

# Download debootstrap package
wget ${GPGV_DEB_URL} --no-clobber -O gpgv.deb
mkdir -p gpgv
cd gpgv
ar x ../gpgv.deb
tar xf data.tar.xz
cd ..

wget ${CERTIFICATE_DEB_URL} --no-clobber -O certificates.deb
mkdir -p certs
cd certs
ar x ../certificates.deb
tar xf data.tar.xz
cd ..

wget ${KEYRINGS_DEB_URL} --no-clobber -O debian-archive-keyring.deb
mkdir -p keyring
cd keyring
ar x ../debian-archive-keyring.deb
tar xf data.tar.xz
cp --parents -r usr/ ../
cd ..

wget ${CDEBOOTSTRAP_STATIC_DEB_URL} --no-clobber -O cdebootstrap-static.deb
mkdir -p cdebootstrap-static
cd cdebootstrap-static
ar x ../cdebootstrap-static.deb
tar xf data.tar.xz
cp --parents -r usr/ ../
cd ..
rm -rf cdebootstrap-static

cd ..

# Create initramfs
mkdir -p initrd/{bin,dev,mnt,proc,sys,tmp,var,etc,usr/share/udhcpc,etc/ssl/certs}
cd initrd
cp ../deps/{busybox,curl} ./bin
cp -r ../deps/usr/* ./usr
cp -a ../deps/kmods/lib .
cat ../deps/certs/usr/share/ca-certificates/mozilla/*.crt > ./etc/ssl/certs/ca-certificates.crt
cp ../deps/gpgv/usr/bin/gpgv-static bin/gpgv

echo "#!/bin/busybox sh
/bin/busybox --install -s /bin

mount -t devtmpfs  devtmpfs  /dev
mount -t proc      proc      /proc
mount -t sysfs     sysfs     /sys
mount -t tmpfs     tmpfs     /tmp

for mod in ${KERNEL_MODULES[@]}; do
    modprobe \$mod
done

udhcpc -v

setsid cttyhack sh" >init
chmod +x init

echo '#!/bin/sh

case $1 in
    deconfig)
        ip link set $interface up
        ;;

    renew|bound)
        ip link set $interface up
        ip addr add $ip/$mask dev $interface
        
        ip route add default via $router dev $interface

        echo "nameserver $dns" > /etc/resolv.conf
        ;;
esac
' > usr/share/udhcpc/default.script
chmod +x usr/share/udhcpc/default.script

find . | cpio -ov --format=newc | gzip -9 >../initramfs
cd ..

mkdir -p rootfs/boot/grub
cd rootfs
cp ../initramfs ../deps/vmlinuz ./boot/
echo "linux /boot/vmlinuz ro quiet console=ttyS0
initrd /boot/initramfs
boot" >boot/grub/grub.cfg
cd ..
grub-mkrescue -o ministaller.iso ./rootfs
