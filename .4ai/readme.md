# Prompt: Generate the project's `README.md`

## Role
You are a technical writer and Linux systems engineer. Write a clear, accurate,
and complete `README.md` for this project by reading the actual source code —
never invent behavior. If code and this prompt ever disagree, trust the code and
note the discrepancy.

## Deliverable
A single `README.md` at the repository root, written in GitHub-flavored Markdown.
Tone: concise, practical, welcoming to contributors. Prefer short paragraphs,
runnable code blocks, and tables over walls of text. Do not use emojis.

## What this project is (ground truth)
A minimal, hackable image builder for bootable Linux ISOs — think of it as a
"mini Buildroot/Yocto" implemented in plain POSIX `sh` instead of a large build
framework. The design goal is radical simplicity: a target is just a declarative
list of building blocks, and each building block is a small, self-contained shell
script. This makes it trivial for the community to read, edit, remix, and
contribute new targets and tools.

Core idea to convey in the README:
- **Targets** (`targets/*.lst`) are declarative recipes: a newline-separated list
  of tool names, one per line. Users pick "puzzle pieces" by editing this file.
- **Tools** (`tools/*.sh`) are the puzzle pieces: each downloads/extracts a
  component (busybox, static curl, a kernel, kernel modules, glibc, gpgv,
  CA certificates, Debian keyrings, cdebootstrap, ...) into the image tree.
- The entrypoint assembles the pieces into an initramfs + kernel and packages a
  bootable `.iso` with `grub-mkrescue`.

## How it actually works (derive details from the code, keep this accurate)
Trace and document the real flow:

1. `iso-installer.sh <target.lst>` is the entrypoint. Summarize its behavior:
   - Exports build paths: `BINARIES_DIST` (download/cache dir, `./bins`),
     `BUILD_DIR` (`./build`), `ROOTFS_DIST` (`build/rootfs`), `INITRD_DIST`
     (`build/initrd`).
   - Validates the config argument exists, else prints usage and exits.
   - Copies the version-controlled `initrd/` and `rootfs/` skeletons into `build/`.
   - Reads the target `.lst` and runs each listed `tools/<name>.sh` with
     `"$INITRD_DIST" "$BINARIES_DIST"` as arguments (installing components into
     the initramfs tree).
   - Always runs `install-kernel.sh` (into the rootfs `boot/`) and
     `install-initrd.sh` (packs the initramfs into `rootfs/boot/initramfs`).
   - Derives the output name from the target file (`foo.lst` -> `foo.iso`) and
     builds it with `grub-mkrescue`.
2. Tool script contract — document the shared convention so contributors can write
   new tools by copying an existing one:
   - Signature: `install_<name> [dest_dir] [bin_cache_dir]`, called as
     `install_<name> "$@"` at the bottom of the file.
   - `dest_dir` (default `$PWD`) is the target tree to install into;
     `bin_cache_dir` (default `$BINARIES_DIST`) caches downloads.
   - Each tool exposes an overridable `*_URL`/`*_DEB_URL` environment variable
     pinning the upstream artifact, and uses `wget --no-clobber` so cached
     downloads are reused across runs.
   - Debian `.deb` sources are unpacked with `ar x` + `tar xf data.tar.xz` in a
     `mktemp -d` scratch dir that is cleaned up afterward.
3. The initramfs `init` (`initrd/init`): installs busybox applets, mounts
   `devtmpfs`/`proc`/`sysfs`/`tmpfs`, `modprobe`s every module listed in
   `usr/share/kernel-modules.lst`, brings up networking via `udhcpc`, and drops
   into an interactive shell.
4. GRUB config (`rootfs/boot/grub/grub.cfg`) boots `vmlinuz` + `initramfs` on the
   serial console.
5. The `vm/` helper (`vm/install-debian.sh` + `install-debian.exp`): builds the
   `debian-installer` target, creates a raw disk image, and drives QEMU with
   `expect` to run `cdebootstrap` and produce a bootable minimal Debian install —
   present it as an end-to-end example of what a target enables.

## Required README sections
1. **Title + one-line description.**
2. **Overview** — what it is, the Buildroot/Yocto analogy, the "declarative
   targets + composable shell tools" philosophy, and why simplicity matters.
3. **Features / Highlights** — bullets (pure POSIX sh, no framework, cached
   downloads, pinned reproducible URLs, easy to fork a tool/target, serial-console
   friendly, produces a real GRUB ISO).
4. **How it works** — the build pipeline above, ideally with a simple diagram
   (target list -> tools populate initrd tree -> kernel + initramfs -> grub ISO).
   A small ASCII/Mermaid flow is welcome.
5. **Requirements** — host tools the scripts rely on (`sh`, `wget`, `ar`, `tar`,
   `cpio`, `gzip`, `grub-mkrescue`/`grub2` + `xorriso`, and for the VM example
   `qemu-system-x86_64`, `kvm`, `expect`, `truncate`). Note it targets `x86_64`.
6. **Quick start** — clone, then
   `./iso-installer.sh targets/debian-installer.lst`, and where the resulting
   `.iso` lands. Show how to boot/test it (the QEMU example).
7. **Targets** — explain the `.lst` format, walk through the shipped
   `targets/debian-installer.lst` and what each listed tool contributes, and how
   to create a custom target.
8. **Tools reference** — a table of the `tools/*.sh` scripts: name, what it
   installs, source URL env var, install location in the tree. Include every
   tool in `tools/` (busybox, curl, gpgv, ca-certificates, keyrings, glibc,
   debootstrap, kernel, kernel-modules, initrd).
9. **Writing a new tool** — the contract from section 2 above, plus a minimal
   copy-paste template.
10. **Kernel modules** — role of `initrd/usr/share/kernel-modules.lst` (loaded at
    boot and used to select `.ko` files to copy in).
11. **The `vm/` Debian example** — how to run it and what it produces.
12. **Roadmap / Contributing** — the project's aim is to grow a library of
    targets for real-world uses (e.g. storage repair, network troubleshooting,
    rescue/recovery). Existing targets double as templates. Invite PRs.
13. **License** — reference the `LICENSE` file.

## Accuracy rules
- Verify every path, filename, env var, and default URL against the source before
  writing it; do not hardcode versions that might drift — refer to the tool
  scripts as the source of truth for pinned URLs.
- Keep example commands copy-pasteable and correct for a POSIX shell.
- Do not document features that don't exist in the code. If something is a
  limitation (x86_64 only, Debian-centric sources, interactive expect flow),
  state it plainly.
- Assume the reader is a competent Linux user but new to this repo.
