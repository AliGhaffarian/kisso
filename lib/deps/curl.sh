#!/usr/bin/env sh

CURL_URL=${CURL_URL:-"https://github.com/moparisthebest/static-curl/releases/latest/download/curl-amd64"}

install_curl() {
	mkdir -p bin

	wget "$CURL_URL" --no-clobber -O "$BINARIES_DIST"/curl
	install -m 755 "$BINARIES_DIST"/curl bin
}
