# kisso

A minimal, hackable image builder for bootable Linux ISOs — a mini
Buildroot/Yocto implemented in plain POSIX shell.

## Overview

kisso builds bootable `x86_64` Linux ISO images out of small, composable pieces.
Instead of a large build framework, it uses two simple ideas:

- **Targets** (`targets/*.lst`) are declarative recipes — a newline-separated
  list of tool names, one per line. You choose which "puzzle pieces" go into
  your image by editing this file.
- **Tools** (`tools/*.sh`) are the puzzle pieces — each is a small,
  self-contained shell script that downloads or extracts a component (busybox,
  static curl, a kernel, kernel modules, glibc, gpgv, CA certificates, Debian
  keyrings, cdebootstrap, ...) into the image tree.

The entrypoint runs the tools listed by your target, assembles the results into
an initramfs plus a kernel, and packages a bootable `.iso` with
`grub-mkrescue`. Everything is plain `sh`, so the whole thing is easy to read,
fork, and extend. Like Buildroot or Yocto, but small enough to understand in one
sitting.

## Features

- Pure POSIX `sh` — no build framework, no DSL, no toolchain to learn.
- Declarative targets: pick components by editing a simple list.
- Composable tools: each component is an isolated, copy-pasteable script.
- Cached downloads (`wget --no-clobber`) reused across builds.
- Reproducible-ish: every tool pins its upstream artifact via an overridable
  URL environment variable.
- Serial-console friendly (boots on `ttyS0`), ideal for QEMU and headless use.
- Produces a real GRUB rescue ISO you can boot on hardware or in a VM.

## How it works

```
targets/foo.lst ──▶ iso-installer.sh
                        │
                        │  for each tool in the list
                        ▼
                 tools/<name>.sh ──▶ populate build/initrd/ tree
                        │
                        ├─ install-kernel.sh   ──▶ build/rootfs/boot/vmlinuz
                        ├─ install-initrd.sh   ──▶ build/rootfs/boot/initramfs
                        ▼
                 grub-mkrescue ──▶ foo.iso
```

`iso-installer.sh <target.lst>` is the entrypoint. It:

1. Exports build paths: `BINARIES_DIST` (download/cache dir, `./bins`),
   `BUILD_DIR` (`./build`), `ROOTFS_DIST` (`build/rootfs`), and `INITRD_DIST`
   (`build/initrd`).
2. Validates the config argument exists, printing usage and exiting otherwise.
3. Copies the version-controlled `initrd/` and `rootfs/` skeletons into `build/`.
4. Reads the target `.lst` and runs each listed `tools/<name>.sh` with
   `"$INITRD_DIST" "$BINARIES_DIST"` as arguments, installing components into the
   initramfs tree.
5. Always runs `install-kernel.sh` (installs `vmlinuz` into the rootfs `boot/`)
   and `install-initrd.sh` (packs the initramfs into `rootfs/boot/initramfs`).
6. Derives the output name from the target file (`foo.lst` → `foo.iso`) and
   builds it with `grub-mkrescue`.

At boot, GRUB (`rootfs/boot/grub/grub.cfg`) loads `vmlinuz` and `initramfs` on
the serial console. The initramfs `init` (`initrd/init`) installs busybox
applets, mounts `devtmpfs`/`proc`/`sysfs`/`tmpfs`, `modprobe`s every module
listed in `usr/share/kernel-modules.lst`, brings up networking with `udhcpc`,
and drops you into an interactive shell.

## Requirements

The build host needs (all common on Linux):

- `sh`, `wget`, `ar`, `tar`, `cpio`, `gzip`
- `grub-mkrescue` (GRUB 2) and `xorriso`

For the QEMU/Debian example under `vm/`:

- `qemu-system-x86_64` with KVM
- `expect`
- `truncate`

kisso targets **`x86_64`** only — the pinned kernel, busybox, and `.deb`
artifacts are all amd64.

## Quick start

```sh
git clone git@github.com:alirezaarzehgar/kisso.git
cd kisso
./iso-installer.sh targets/debian-installer.lst
```

This produces `debian-installer.iso` in the repository root. Downloaded
artifacts are cached under `bins/` and intermediate build output lands in
`build/` — all three (`build/`, `bins/`, `*.iso`) are git-ignored, so only the
`initrd/` and `rootfs/` skeletons are tracked.

Boot the result in QEMU to try it:

```sh
qemu-system-x86_64 -cdrom debian-installer.iso -m 2G -nographic -serial mon:stdio
```

## Targets

A target is a plain text file listing tool names — one per line, no extension.
Each line names a script in `tools/` (without the `.sh` suffix), and the tools
run top to bottom.

The shipped `targets/debian-installer.lst`:

| Line | Tool | Contribution |
|------|------|--------------|
| `install-busybox` | busybox | Core userland / init shell |
| `install-kernel-modules` | kernel modules | `.ko` files listed in `kernel-modules.lst` |
| `install-curl` | static curl | HTTPS downloads at runtime |
| `install-gpgv` | gpgv | Signature verification for apt/debootstrap |
| `install-ca-certificates` | CA bundle | TLS trust store |
| `install-keyrings` | Debian keyrings | Debian archive signing keys |
| `install-debootstrap` | cdebootstrap | Bootstraps a Debian system |

Together these produce an image capable of bootstrapping a fresh Debian install
over the network.

To create your own target, drop a new `.lst` in `targets/` listing the tools you
want, then build it:

```sh
./iso-installer.sh targets/my-rescue.lst
```

## Tools reference

Every script in `tools/`:

| Tool | Installs | URL env var | Install location (in tree) |
|------|----------|-------------|-----------------------------|
| `install-busybox` | static busybox binary | `BUSYBOX_URL` | `bin/busybox` |
| `install-curl` | static curl binary | `CURL_URL` | `bin/curl` |
| `install-gpgv` | gpgv (from `gpgv-static` deb) | `GPGV_DEB_URL` | `bin/gpgv` |
| `install-ca-certificates` | Mozilla CA bundle | `CERTIFICATE_DEB_URL` | `etc/ssl/certs/ca-certificates.crt` |
| `install-keyrings` | Debian archive keyrings | `KEYRINGS_DEB_URL` | `usr/share/keyrings/` |
| `install-glibc` | glibc shared libs + dynamic linker | `GLIBC_DEB_URL` | `usr/lib/...`, `lib64/ld-linux-x86-64.so.2` |
| `install-debootstrap` | `cdebootstrap-static` → `cdebootstrap` | `CDEBOOTSTRAP_STATIC_DEB_URL` | `usr/bin/cdebootstrap` |
| `install-kernel` | `vmlinuz` (from linux-image deb) | `KERNEL_DEB_URL` | `boot/vmlinuz` |
| `install-kernel-modules` | selected `.ko` modules | `KERNEL_DEB_URL` | `lib/modules/*-amd64/` |
| `install-initrd` | packs the initramfs archive | — | `<rootfs>/boot/initramfs` |

The pinned default URLs live at the top of each script; treat those scripts as
the source of truth for exact versions, since they may change over time. Each
URL can be overridden via its environment variable, e.g.:

```sh
KERNEL_DEB_URL=https://example.com/linux-image.deb \
  ./iso-installer.sh targets/debian-installer.lst
```

Note that `install-kernel` and `install-initrd` are run automatically by
`iso-installer.sh` and do not need to be listed in a target. `install-glibc`
ships as an available tool but is not part of `debian-installer.lst`; add it to
a target if your image needs dynamically linked glibc executables.

## Writing a new tool

Tools share a simple contract, so the easiest way to write one is to copy an
existing script. Each tool:

- Defines `install_<name> [dest_dir] [bin_cache_dir]` and calls
  `install_<name> "$@"` at the bottom of the file.
- Uses `dest_dir` (default `$PWD`) as the target tree to install into, and
  `bin_cache_dir` (default `$BINARIES_DIST`) as the download cache.
- Exposes an overridable `*_URL` / `*_DEB_URL` environment variable pinning the
  upstream artifact, downloaded with `wget --no-clobber` so caches are reused.
- Unpacks Debian `.deb` sources with `ar x` + `tar xf data.tar.xz` inside a
  `mktemp -d` scratch dir that is removed afterward.

Minimal template:

```sh
#!/usr/bin/env sh

FOO_URL=${FOO_URL:-"https://example.com/foo-amd64"}

# install_foo [dest_dir] [bin_cache_dir]
install_foo() {
	dest_dir=${1:-$PWD}
	bin_cache_dir=${2:-$BINARIES_DIST}

	mkdir -p "$dest_dir/bin"

	wget "$FOO_URL" --no-clobber -O "$bin_cache_dir/foo"
	install -m 755 "$bin_cache_dir/foo" "$dest_dir/bin/foo"
}

install_foo "$@"
```

Save it as `tools/install-foo.sh` and add `install-foo` to a target list.

## Kernel modules

`initrd/usr/share/kernel-modules.lst` lists the kernel modules your image needs
(ext4, virtio, networking, etc.). It is used twice:

- At **build time**, `install-kernel-modules.sh` copies the matching `.ko` files
  out of the kernel `.deb` into `lib/modules/*-amd64/`.
- At **boot time**, `initrd/init` `modprobe`s each listed module.

Edit this file to match the hardware and filesystems your target must support.

## The `vm/` Debian example

`vm/install-debian.sh` is an end-to-end demonstration of what a target enables.
It builds the `debian-installer` target, creates a 4G raw disk image, and drives
QEMU with `expect` (`vm/install-debian.exp`) to partition the disk, run
`cdebootstrap`, install GRUB, and produce a bootable minimal Debian system.

```sh
./vm/install-debian.sh
```

The Debian mirror is configurable via `DEBIAN_MIRROR`. The flow is interactive
(scripted through `expect`) and sets the installed root password to `admin`.

## Roadmap / Contributing

The goal of kisso is to grow a library of targets for real-world uses — storage
repair, network troubleshooting, rescue/recovery, and more. The existing
targets and tools double as templates: copy one, tweak it, and open a PR.
Contributions of new tools and targets are very welcome.

## License

See [LICENSE](LICENSE).
