# Prompt: generate docs/debian-installer.md

## Role
You are a technical writer and Linux systems engineer. Write a clear, accurate,
and genuinely helpful `docs/debian-installer.md` — an installation guide for end
users who already have a `debian-installer.iso` and want to install a complete,
minimal Debian system onto a real (or virtual) storage device.

Model the document on the **Arch Linux Installation Guide**
(https://wiki.archlinux.org/title/Installation_guide): concise numbered phases,
imperative prose, and — most importantly — realistic terminal transcripts that
show the actual commands *and their representative output* so the reader knows
what success looks like at each step.

Standing rules:
- Read the actual source before writing. The authoritative reference for the
  install procedure is `vm/install-debian.exp`; the ISO's runtime environment is
  defined by `initrd/init`, `initrd/usr/share/kernel-modules.lst`,
  `rootfs/boot/grub/grub.cfg`, and the tools listed in
  `targets/debian-installer.lst`. If the code and this prompt disagree, trust the
  code and note the discrepancy.
- This document does NOT teach the kisso / `iso-installer.sh` build project. It
  assumes the reader already has the ISO and only wants to use it. Do not explain
  how the ISO is built; link to the README for that.

## Deliverable
- Output path: `docs/debian-installer.md`.
- Format: GitHub-flavored Markdown. No emojis.
- Audience: a competent Linux user comfortable with the shell, partitioning, and
  chroot, but new to this ISO.

## Presentation style (important — this is what to get right)
The previous version was too dry. Make it feel like a real session, Arch-wiki
style:

- Show interaction as **`console` transcripts** that include the shell prompt,
  the typed command, and a trimmed but *representative* sample of the program's
  real output — so the user can compare against what they see. Use fenced blocks
  tagged ```` ```console ````.
- Use the **real prompts** from this ISO: the BusyBox rescue prompt is `/ #`
  (and `/mnt #` after `cd /mnt`), and inside the chroot it is `root@(none):/#`.
- Keep output **trimmed with `...`** where a program is verbose (e.g.
  `cdebootstrap`, `mkfs.ext2`, `grub-install`), but keep the lines that prove the
  step worked (e.g. "lease of ... obtained", "The partition table has been
  altered", "Installation finished. No error reported.").
- For interactive tools (`fdisk`, `passwd`, `adduser`), show the prompts and the
  answers the user types inline, exactly as they appear on screen.
- Prefer showing the **natural interactive flow** a human would actually type
  (e.g. `mkdir /mnt` + `cd /mnt` then `cdebootstrap ... .`, `cd ..`), rather than
  the terse scripted one-liners from the `.exp` file — but keep the same
  effective result and command set. When the `.exp` file and a friendlier manual
  flow differ only in style (bind syntax `mount --bind` vs `mount -o bind`,
  copying `/etc/ssl` before chroot, etc.), either is fine as long as it works;
  choose the clearer one and stay consistent.

Use this transcript as the reference for tone, prompts, and output density (the
generated doc should read like this, adapted per step):

```console
udhcpc: lease of 192.168.122.17 obtained, lease time 3600
udhcpc: executing /usr/share/udhcpc/default.script bound
udhcpc: entering listen mode: none

/ # fdisk /dev/vda

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

/ # mkfs.ext2 /dev/vda1
...
/ # mkdir /mnt
/ # cd /mnt
/mnt # cdebootstrap --flavour=minimal bookworm . https://deb.debian.org/debian
P: Retrieving Release
...
P: Writing resolv.conf
/mnt # cd ..
/ # chroot /mnt/
root@(none):/#
```

## Ground truth / context (verify against the source)
The ISO boots into a BusyBox initramfs shell (see `initrd/init`): it mounts the
pseudo-filesystems, loads the kernel modules from
`usr/share/kernel-modules.lst`, brings up networking with `udhcpc` (show the
DHCP lease output), and drops the user at an interactive `/ #` prompt on the
serial console. The environment ships the tools from
`targets/debian-installer.lst` (busybox, curl, gpgv, ca-certificates, Debian
keyrings, and `cdebootstrap`). The install itself is performed with
`cdebootstrap`, not the Debian Installer.

Derive the steps from `vm/install-debian.exp`. The effective sequence is:
1. Inspect and partition the target disk with `fdisk` (one primary partition).
2. Make a filesystem (`mkfs.ext2`) and mount it (`mkdir /mnt; mount /dev/vda1 /mnt`,
   or `cd` into it for the bootstrap).
3. Bootstrap Debian with `cdebootstrap --flavour=minimal ... bookworm <target>
   <mirror>`. The `.exp` file passes
   `--include=systemd-sysv,udev,linux-image-amd64,initramfs-tools,grub-pc-bin,grub2-common,grub-common`;
   present that include list as the reliable path so the resulting system is
   directly bootable, and you may additionally show how to add pieces from inside
   the chroot with `apt` if preferred.
4. Copy TLS trust (`/etc/ssl`) into the target and bind-mount `/dev`, `/proc`,
   `/sys`, then `chroot /mnt`.
5. Inside the chroot: set hostname, write `/etc/fstab`, add the virtio modules to
   `/etc/initramfs-tools/modules`, create/set credentials (`passwd` for root
   and/or `adduser`), `update-initramfs -c -k all`, `grub-install /dev/vda`,
   `grub-mkconfig -o /boot/grub/grub.cfg`, `update-grub`.
6. Exit the chroot, unmount, and reboot into the installed system.

Preserve the real device names, suite (`bookworm`), and command order. Note
where values are examples the reader should adapt (target disk device, mirror
URL, hostname, username, password) versus fixed requirements. In transcripts,
disks show as `/dev/vda` (QEMU virtio); mention `/dev/sdX` for real hardware.

## Required sections / steps (in order)
1. **Title + intro** — one short paragraph: what this guide does and what it
   assumes (you have the ISO), plus a one-line link to the README for building
   the ISO.
2. **Get the ISO** — download a prebuilt image from
   `https://github.com/alirezaarzehgar/kisso/releases`, or build it (link README).
3. **Prerequisites & warnings** — `x86_64`; the target disk will be **erased**;
   network required; serial console.
4. **Boot the ISO** — a concrete `qemu-system-x86_64` invocation consistent with
   `vm/install-debian.exp` (virtio disk, user networking, `-nographic -serial
   mon:stdio`), plus a short note on real hardware (write to USB with `dd`). End
   with a `console` transcript showing the `udhcpc` DHCP lease and the landing
   `/ #` prompt, and how to sanity-check networking (`ip addr`, `ping`).
5. **Inspect & partition the disk** — `fdisk -l` to identify the device, then an
   interactive `fdisk /dev/vda` transcript creating one primary partition (n → p
   → 1 → defaults → w), including the "partition table has been altered" line.
6. **Create filesystem & mount** — `mkfs.ext2 /dev/vda1` (trimmed output) and
   mounting at `/mnt`.
7. **Bootstrap Debian** — the `cdebootstrap` command (mirror as an adaptable
   value) with trimmed `P:` output ending in the "Writing resolv.conf" lines.
8. **Enter the chroot** — copy `/etc/ssl`, bind-mount `/dev` `/proc` `/sys`,
   `chroot /mnt`, showing the prompt change to `root@(none):/#`.
9. **Configure the system (inside chroot)** — hostname, `/etc/fstab`, initramfs
   virtio modules, set root password and/or `adduser` (show the interactive
   `adduser`/`passwd` transcript), `update-initramfs -c -k all`, then
   `grub-install /dev/vda` (show "Installation finished. No error reported.") and
   `grub-mkconfig -o /boot/grub/grub.cfg` / `update-grub`.
10. **Finish & reboot** — exit chroot, `umount -a`, power off, remove the ISO /
    change boot order, and boot the disk (show a QEMU boot-from-disk command).
11. **Post-install** — brief: log in, `apt update`, add a user if not already,
    basic networking. Keep short.
12. **Troubleshooting** — no network at the prompt (re-run `udhcpc`), wrong disk
    device, boot drops to initramfs (missing virtio modules /
    `update-initramfs`), `grub-install` targeting a partition instead of the
    whole disk, TLS/cert errors (missing `/etc/ssl` in target).

## Accuracy rules
- Commands must be copy-pasteable and match what the ISO's shipped tools support;
  do not invent flags or steps.
- Transcript output must be **plausible and representative**, clearly illustrative
  rather than fabricated precision — trim with `...` and keep the meaningful
  confirmation lines.
- Make destructive steps unambiguous and warn before them.
- Clearly mark adaptable values (disk device, mirror, hostname, username,
  password); never present a real password as a value to copy blindly.
- State real limitations plainly: minimal `bookworm`, ext2 root, BIOS/GRUB-PC
  boot (`grub-pc-bin`), x86_64/virtio-oriented module set.
- Do not document the build system; keep the focus on using the ISO.
