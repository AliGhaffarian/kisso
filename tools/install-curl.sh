#!/usr/bin/env sh

CURL_URL=${CURL_URL:-"https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64"}

# install_curl [dest_dir] [bin_cache_dir]
#
# download and install the static curl binary into the target root filesystem.
# The binary is placed in ${dest_dir}/bin/curl.
#
# args:
# - dest_dir (default=current dir): target directory to install curl
# - bin_cache_dir (default=$BINARIES_DIST): download and cache binaries
#
# envs:
# - CURL_URL: URL of the static curl binary
# - BINARIES_DIST: default path for caching downloaded binaries
install_curl() {
	dest_dir=${1:-$PWD}
	bin_cache_dir=${2:-$BINARIES_DIST}

	mkdir -p "$dest_dir/bin"

	wget "$CURL_URL" --no-clobber -O "$bin_cache_dir/curl"
	install -m 755 "$bin_cache_dir/curl" "$dest_dir/bin/curl"
}

install_curl "$@"
