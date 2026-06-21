# How to test it

truncate -s 20G disk.img

qemu-system-x86_64 \
    -kernel deps/vmlinuz \
    -initrd initramfs \
    -m 1G \
    -enable-kvm \
    -append "console=ttyS0" \
    -nographic \
    -drive file=disk.img,format=raw,if=virtio \
    -netdev user,id=n1 \
    -device virtio-net-pci,netdev=n1

