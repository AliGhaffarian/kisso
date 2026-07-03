# Shared environment variables for build
BINARIES_DIST=${PWD}/bins
BUILD_DIR=${PWD}/build
ROOTFS_DIST=${BUILD_DIR}/rootfs
INITRD_DIST=${BUILD_DIR}/initrd

# import all dependency installer functions from deps directory
for dep in $(ls -1 ./lib/deps); do
. ./lib/deps/$dep
done

# Create build directory in currect dir and copy initrd/rootfs template
# for new build.
create_build_dir() {
    mkdir -p ${BUILD_DIR} ${BINARIES_DIST}
    cp -r initrd rootfs ${BUILD_DIR}
}
