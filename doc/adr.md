# Minimal x86_64 Linux Installation ISO

## Functional Requirements

* The ISO image must boot on x86_64 systems.
* A bootloader must be included. The simplest possible solution is preferred (e.g., a minimal GRUB configuration or an alternative lightweight bootloader).
* A Linux kernel must be included. Whether it is built from source or obtained as a precompiled binary is an implementation detail.
* An initramfs must be provided to perform the initial boot-time setup.
* A shell and basic Linux utilities must be available through BusyBox.
* Basic partitioning and filesystem tools must be available (e.g., fdisk, mkfs, mount).
* A solution for installing a Debian root filesystem must be included (e.g., debootstrap or a similar tool).
* A package manager must be available and capable of installing packages into another filesystem.

The user must be able to boot the ISO image and install a complete Linux system.

This project is responsible for providing the minimum set of tools required to:

* Partition disks
* Create filesystems
* Mount partitions
* Install the required packages
* Chroot into the target filesystem
* Continue the installation process within the target filesystem

The project is not responsible for providing a complete operating system inside the ISO image, and this requirement must not significantly affect the ISO size.

The project should be well documented and provide sufficient guidance for beginners.

The goal of this project is to provide a super-minimal Linux image for testing, debugging, installation, and learning purposes.

## Non-Functional Requirements / Architectural Characteristics

* The ISO image size must not exceed 50 MB.
* Static binaries are preferred to minimize maintenance effort and runtime dependencies.
* ISO images must be published through GitHub Releases using GitHub Actions automation.
* The build process must be fully reproducible, containerized, and independent of the host machine.
* The project targets common home PCs, laptops, and QEMU virtual machines. It is not intended to be a universal solution for all hardware configurations.

The primary design goals are simplicity, maintainability, reproducibility, and the avoidance of unnecessary tools, abstractions, and dependencies.

## Technology Choices

* bootloader: GRUB
* kernel: extracted from a Debian kernel package
* initramfs: manually built
* shell, basic utilities, networking, and partitioning tools: BusyBox
* installer: debootstrap
* build environment: Docker
* CI/CD: GitHub Actions

## Architecture

The project generates a bootable ISO image. The build process runs inside a Debian-based Docker environment.

Each step of the ISO generation process is implemented as a separate Bash script executed within a Docker multi-stage build. The final stage aggregates the outputs of all previous stages and generates the ISO image.

Each stage should have its own script to keep the Dockerfile clean and focused on orchestrating the build pipeline.

Directory structure:

```plaintext
├── Dockerfile
├── .github
│   └── workflows
│       └── all.yaml
└── stages
    ├── build-initrd.sh
    ├── build-iso.sh
    ├── download-deps.sh
    └── delivery.sh
```

All actions can be performed through CI/CD by building the Docker image in CI, pushing it to a container registry, and then automatically publishing the generated ISO to GitHub Releases during CD by pulling the image and extracting the generated ISO artifact.

### Prepare Requirements

This step downloads all required dependencies and archives them for use in subsequent stages.

* Download the BusyBox static binary.
* Download and extract the Debian Linux kernel from the `linux-image-amd64` package.
* Download debootstrap and all of its dependencies.

### Build Initramfs

* Create the initramfs filesystem structure with all required dependencies.
* Add the init script.
* Archive the filesystem and generate the initrd image.

```bash
echo "#!/bin/busybox sh
/bin/busybox --install -s /bin

mount -t devtmpfs  devtmpfs  /dev
mount -t proc      proc      /proc
mount -t sysfs     sysfs     /sys
mount -t tmpfs     tmpfs     /tmp

setsid cttyhack sh" >init

chmod +x init
find . | cpio -ov --format=newc | gzip -9 >boot/initramfs
```

### Generate ISO

* Install the dependencies required by `grub-mkrescue`.
* Place the kernel and initrd into the ISO filesystem.
* Add the bootloader configuration to the ISO filesystem.
* Generate the ISO image using `grub-mkrescue`.

### Release

* Copy the generated ISO file into a minimal scratch-based Docker image for artifact delivery.
