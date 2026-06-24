# Kisso

Kisso is a minimal Linux ISO project focused on providing small, purpose-built bootable environments.

The name is a combination of **KISS** (*Keep It Simple, Stupid*) and **ISO**.

The project exists because modern installation media has become increasingly large and complex. Kisso takes the opposite approach: provide only the tools required to perform a specific task and let the user build the rest.

The first image provided by the project is a Debian installer built around a minimal userspace and `cdebootstrap`.

Current ISO size is approximately **26 MB**.

## Goals

Kisso aims to provide:

* Extremely small bootable images.
* A Debian installation experience that is transparent and easy to understand.
* Manual system installation without hiding important steps.
* Recovery and maintenance environments.
* Reproducible and auditable build processes.

A secondary goal is to bring an installation experience closer to Arch Linux, where users can build a system from the ground up, while still ending up with a standard Debian installation.

Instead of a large graphical installer, Kisso boots into a minimal shell environment and provides the tools necessary to install Debian manually.

## How It Works

Kisso boots into a small Linux environment containing:

* BusyBox
* Networking utilities
* Debian archive keyrings
* CA certificates
* `gpgv`
* `cdebootstrap`

Networking is configured automatically during boot using `udhcpc`.

Once the system has network connectivity, Debian can be installed directly from official Debian repositories.

The installation process relies on `cdebootstrap`, a lightweight alternative to Debian's traditional installer infrastructure. `cdebootstrap` downloads and verifies Debian packages, creates the base system, and prepares a bootstrappable Debian environment.

The resulting installation is a normal Debian system. No custom packages, repositories, or modifications are required.

## Why Not the Official Debian Installer?

The official Debian installer is a mature and feature-rich project, but it also includes many components that are unnecessary for users who prefer complete control over the installation process.

Kisso intentionally removes that complexity.

The goal is not to replace the Debian installer. The goal is to provide a small and understandable alternative for users who prefer to partition disks, bootstrap the system, install packages, and configure the machine themselves.

## Virtual Machines

Kisso works particularly well inside virtual machines.

The generated ISO can be booted directly using:

* QEMU
* virt-manager
* libvirt

A typical workflow is:

1. Create a virtual machine.
2. Attach the generated ISO.
3. Boot the machine.
4. Install Debian manually.
5. Reboot into the installed system.

The current installer has been tested successfully with virt-manager and can be used without special configuration.

## Example Installation

The following transcript demonstrates a complete installation of a minimal Debian system using Kisso.

```console
udhcpc: started, v1.31.0
udhcpc: executing /usr/share/udhcpc/default.script deconfig
udhcpc: entering listen mode: raw
udhcpc: created raw socket
udhcpc: sending discover
udhcpc: waiting 3 seconds
udhcpc: received a packet
udhcpc: sending select for 192.168.122.17
udhcpc: waiting 3 seconds
udhcpc: received a packet
udhcpc: lease of 192.168.122.17 obtained, lease time 3600
udhcpc: executing /usr/share/udhcpc/default.script bound
udhcpc: entering listen mode: none

/ #
/ # fdisk -l
Disk /dev/vda: 25 GB, 26843545600 bytes, 52428800 sectors
52012 cylinders, 16 heads, 63 sectors/track
Units: sectors of 1 * 512 = 512 bytes

Device  Boot StartCHS    EndCHS        StartLBA     EndLBA    Sectors  Size Id Type

/ # fdisk /dev/vda

The number of cylinders for this disk is set to 52012.
There is nothing wrong with that, but this is larger than 1024,
and could in certain setups cause problems with:
1) software that runs at boot time (e.g., old versions of LILO)
2) booting and partitioning software from other OSs
   (e.g., DOS FDISK, OS/2 FDISK)

Command (m for help): n
Partition type
   p   primary partition (1-4)
   e   extended
p
Partition number (1-4): 1
First sector (63-52428799, default 63):
Using default value 63
Last sector or +size{,K,M,G,T} (63-52428799, default 52428799):
Using default value 52428799

Command (m for help): w

The partition table has been altered.
Calling ioctl() to re-read partition table

/ #
/ # mkfs.ext2 /dev/vda1

Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
1638400 inodes, 6553592 blocks
327679 blocks (5%) reserved for the super user
First data block=0
Maximum filesystem blocks=8388608
200 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group

Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912,
        819200, 884736, 1605632, 2654208, 4096000

/ # mkdir /mnt
/ # cd /mnt

/mnt # cdebootstrap --flavour=minimal bookworm . https://deb.debian.org/debian

P: Retrieving Release
P: Retrieving Release.gpg
P: Validating Release
...
P: Deconfiguring helper cdebootstrap-helper-makedev
P: Writing apt sources.list
P: Writing hosts
P: Writing resolv.conf

/mnt # cd ..
/ #

/ # cp -r /etc/ssl/ /mnt/etc/

/ # mount -o bind /dev/ /mnt/dev/
/ # mount -o bind /proc/ /mnt/proc/
/ # mount -o bind /sys/ /mnt/sys/

/ # chroot /mnt/

root@(none):/# adduser ali

Adding user `ali' ...
Adding new group `ali' (1000) ...
Adding new user `ali' (1000) with group `ali (1000)' ...
Creating home directory `/home/ali' ...
Copying files from `/etc/skel' ...

New password:
Retype new password:
passwd: password updated successfully

Changing the user information for ali
Enter the new value, or press ENTER for the default

        Full Name []:
        Room Number []:
        Work Phone []:
        Home Phone []:
        Other []:

Is the information correct? [Y/n] y

Adding new user `ali' to supplemental / extra groups `users' ...
Adding user `ali' to group `users' ...

root@(none):/# apt update
root@(none):/# apt install grub
root@(none):/# apt install linux-image-amd64

root@(none):/# grub-install /dev/vda

Searching for GRUB installation directory ... found: /boot/grub

WARNING: tempfile is deprecated; consider using mktemp instead.
WARNING: tempfile is deprecated; consider using mktemp instead.
WARNING: tempfile is deprecated; consider using mktemp instead.

Installation finished. No error reported.

This is the contents of the device map /boot/grub/device.map.
Check if this is correct or not. If any of the lines is incorrect,
fix it and re-run the script `grub-install'.

(hd0) /dev/vda

root@(none):/# grub-mkconfig > /boot/grub/grub.cfg
```

The result is a fully functional Debian installation created from a minimal bootstrap environment.

## TODO

You can see [issue tracker](https://github.com/alirezaarzehgar/kisso/issues) for TODO tasks.

## Contributing

Contributions are welcome in any form.

Bug reports, documentation improvements, testing, build improvements, feature proposals, pull requests, and code contributions are all appreciated.

## License

Kisso is licensed under the GNU General Public License (GPL).
