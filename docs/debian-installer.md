# Installing Debian with `debian-installer.iso`

This guide walks you through installing a complete, minimal Debian system onto a
storage device using the prebuilt `debian-installer.iso`. It assumes you already
have the ISO and only want to use it — it does not explain how the image is
built (see the [README](../README.md) for that).

The ISO boots into a small BusyBox rescue environment with networking already
up, from which you bootstrap Debian onto your disk with `cdebootstrap` and make
it bootable with GRUB. The procedure below mirrors the automated flow in
`vm/install-debian.exp`, translated into commands you type by hand.

> **Warning:** This process **erases** the target disk. Double-check the device
> name before running any command that writes to it.

## 1. Get the ISO

Download a prebuilt image from the GitHub releases page:

- https://github.com/alirezaarzehgar/kisso/releases

Grab the latest `debian-installer.iso`. Alternatively, build it yourself by
following the [README](../README.md).

## 2. Prerequisites

- An `x86_64` machine or virtual machine (the ISO ships an amd64 kernel and a
  virtio-oriented module set).
- A target disk that may be **completely erased**.
- Working network access — the installer downloads packages from a Debian
  mirror.
- You interact over a **serial console** (the ISO boots with `console=ttyS0`).

## 3. Boot the ISO

### In a virtual machine (QEMU)

Create a disk image and boot the ISO against it. This matches the setup used by
`vm/install-debian.exp` (virtio disk, user-mode networking, serial console):

```sh
# Create a 4 GiB disk image (once)
truncate -s 4G minidebian.img

qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 4G \
  -smp 2 \
  -boot d \
  -drive file=minidebian.img,if=virtio,aio=threads,cache=writeback \
  -cdrom debian-installer.iso \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -serial mon:stdio
```

In this configuration the target disk appears as `/dev/vda`.

### On real hardware

Write the ISO to a USB stick (replace `/dev/sdX` with your USB device — **not**
your target disk):

```sh
sudo dd if=debian-installer.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Then boot the machine from that USB stick (you will need a serial console, or
adapt the boot arguments for a local display).

Once booted, you land at a BusyBox shell prompt:

```
/ #
```

Networking is brought up automatically via DHCP (`udhcpc`), so you should have
an IP address already. You can confirm with `ip addr` and `ping deb.debian.org`.

## 4. Identify and partition the disk

Identify your target disk. In the QEMU example above it is `/dev/vda`; on real
hardware it is typically `/dev/sdX` (e.g. `/dev/sda`). List block devices to be
sure:

```sh
ls /sys/block
```

> The commands below use `/dev/vda`. **Replace it with your actual device.**

Create a single primary partition spanning the whole disk with `fdisk`:

```sh
fdisk /dev/vda
```

At the `fdisk` prompts, enter:

```
n      # new partition
p      # primary
1      # partition number 1
       # first sector: press Enter for default
       # last sector: press Enter for default (use whole disk)
w      # write changes and exit
```

This creates `/dev/vda1`.

## 5. Create a filesystem and mount it

Format the new partition and mount it at `/mnt`:

```sh
mkfs.ext2 /dev/vda1
mount /dev/vda1 /mnt
```

## 6. Bootstrap Debian

Install a minimal Debian `bookworm` into `/mnt` with `cdebootstrap`. The include
list pulls in the essentials to produce a bootable system (init, udev, a kernel,
initramfs tooling, and GRUB):

```sh
DEBIAN_MIRROR=https://deb.debian.org/debian

cdebootstrap \
  --flavour=minimal \
  --include=systemd-sysv,udev,linux-image-amd64,initramfs-tools,grub-pc-bin,grub2-common,grub-common \
  bookworm /mnt "$DEBIAN_MIRROR"
```

> Change `DEBIAN_MIRROR` to a mirror closer to you if you prefer. This step
> downloads a fair amount of data and may take a while.

## 7. Prepare the chroot

Copy the TLS trust store into the target (so tools inside the chroot can verify
HTTPS), then bind-mount the kernel pseudo-filesystems and enter the chroot:

```sh
cp -a /etc/ssl /mnt/etc/
mount --bind /dev  /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys  /mnt/sys
chroot /mnt
```

Your prompt changes to a root shell inside the new system (e.g. `root@...:/#`).

## 8. Configure the system (inside the chroot)

Set the hostname (adapt `debian` to your preference):

```sh
echo debian > /etc/hostname
```

Write `/etc/fstab` so the root filesystem is mounted at boot. This must match the
partition and filesystem you created in steps 4–5 (`/dev/vda1`, `ext2`):

```sh
cat > /etc/fstab <<'FSTAB'
/dev/vda1 / ext2 defaults 0 1
FSTAB
```

Ensure the initramfs includes the virtio modules needed to find the disk at boot
(important for VMs; harmless otherwise):

```sh
echo virtio     >> /etc/initramfs-tools/modules
echo virtio_pci >> /etc/initramfs-tools/modules
echo virtio_blk >> /etc/initramfs-tools/modules
```

Set the root password. **Choose your own strong password** — do not reuse the
example value from the automated script:

```sh
passwd
```

Build the initramfs and install the bootloader. Use the whole disk device for
`grub-install` (`/dev/vda`), not the partition:

```sh
update-initramfs -c -k all
grub-install /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg
update-grub
```

## 9. Finish and reboot

Leave the chroot, unmount everything, and shut down:

```sh
exit          # leave the chroot
umount -a
```

Now power off the VM (or the machine), remove the ISO / change the boot order so
the machine boots from the installed disk, and start it again. For QEMU, drop
`-cdrom` / `-boot d` and boot the disk directly:

```sh
qemu-system-x86_64 \
  -enable-kvm -cpu host -m 4G -smp 2 \
  -drive file=minidebian.img,if=virtio,aio=threads,cache=writeback \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -nographic -serial mon:stdio
```

## 10. Post-install

Log in as `root` with the password you set. A few common first steps:

```sh
# Update package lists and upgrade
apt update && apt upgrade

# Create a regular user
adduser youruser

# Bring up networking if needed (minimal installs are bare)
# e.g. via systemd-networkd, ifupdown, or NetworkManager
```

You now have a minimal Debian base system to build on.

## Troubleshooting

- **No network at the `/ #` prompt.** DHCP may not have completed. Re-run
  `udhcpc`, and check `ip addr` / `ip route`. In QEMU, confirm the
  `-netdev user` / `virtio-net-pci` options are present.
- **Wrong disk device.** If commands target the wrong disk, you can destroy data.
  Verify with `ls /sys/block` and match sizes before partitioning. On hardware
  the target is usually `/dev/sdX`, in QEMU `/dev/vda`.
- **System won't boot / drops to initramfs.** Usually a missing storage driver.
  Make sure the virtio modules were added to `/etc/initramfs-tools/modules` and
  that you ran `update-initramfs -c -k all` before rebooting. Also confirm
  `/etc/fstab` points at the correct partition and filesystem type.
- **`grub-install` fails.** Run it against the whole disk (`/dev/vda`), not a
  partition (`/dev/vda1`), and ensure `grub-pc-bin` was included by
  `cdebootstrap`. This image targets BIOS/GRUB-PC boot.
- **HTTPS/certificate errors during bootstrap.** Ensure the ISO's CA bundle is
  present (it ships `/etc/ssl`); after chroot, verify `/mnt/etc/ssl` was copied
  in step 7.

## Notes and limitations

- Installs a **minimal** Debian `bookworm`; expect to add packages yourself.
- Root filesystem is **ext2** and boot is **BIOS/GRUB-PC** (`grub-pc-bin`).
- The kernel and module set are **x86_64 / virtio-oriented**; bare-metal installs
  may need additional modules for your storage/network hardware.
