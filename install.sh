#!/bin/sh

set -eu

REPOSITORY="eeelin/openwrt-gost"
RELEASE_TAG="v0.1.0"
PACKAGE_VERSION="3.2.6"
PACKAGE_RELEASE="1"
PACKAGE_SHA256="363ee88e03df18631fbcf046a15422ef1b1c8a17ad9c06ee43f8b948154c6fd6"
ENABLE_SERVICE=1

usage() {
	cat <<EOF
Usage: install.sh [--no-enable]

Install openwrt-gost ${RELEASE_TAG} on OpenWrt 25.12 aarch64.

  --no-enable  Do not enable the gost init service at boot
  -h, --help   Show this help
EOF
}

log() {
	printf '%s\n' "[openwrt-gost] $*"
}

die() {
	printf '%s\n' "[openwrt-gost] ERROR: $*" >&2
	exit 1
}

download() {
	url="$1"
	destination="$2"

	if command -v uclient-fetch >/dev/null 2>&1; then
		uclient-fetch -q -O "$destination" "$url"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$destination" "$url"
	elif command -v curl >/dev/null 2>&1; then
		curl -fL --retry 3 -o "$destination" "$url"
	else
		die "uclient-fetch, wget, or curl is required"
	fi
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--no-enable)
			ENABLE_SERVICE=0
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "unknown option: $1"
			;;
	esac
	shift
done

[ "$(id -u)" -eq 0 ] || die "run this installer as root"
[ -r /etc/openwrt_release ] || die "this installer only supports OpenWrt"

# DISTRIB_RELEASE is supplied by OpenWrt and contains no user-controlled data.
# shellcheck disable=SC1091
. /etc/openwrt_release

case "${DISTRIB_RELEASE:-}" in
	25.12*) ;;
	*) die "OpenWrt 25.12 is required (found ${DISTRIB_RELEASE:-unknown})" ;;
esac

case "$(uname -m)" in
	aarch64|arm64) ;;
	*) die "aarch64 is required (found $(uname -m))" ;;
esac

command -v apk >/dev/null 2>&1 || die "apk is required; OpenWrt 24.10 and older are not supported"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required"

package="gost-${PACKAGE_VERSION}-r${PACKAGE_RELEASE}.apk"
url="https://github.com/${REPOSITORY}/releases/download/${RELEASE_TAG}/${package}"
tmpdir="$(mktemp -d /tmp/openwrt-gost.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

log "downloading ${package}"
download "$url" "$tmpdir/$package" || die "failed to download $url"

actual_sha256="$(sha256sum "$tmpdir/$package" | awk '{print $1}')"
[ "$actual_sha256" = "$PACKAGE_SHA256" ] || \
	die "checksum mismatch: expected $PACKAGE_SHA256, got $actual_sha256"
log "checksum verified"

log "installing ${package}"
apk add --allow-untrusted "$tmpdir/$package"

if [ "$ENABLE_SERVICE" -eq 1 ]; then
	/etc/init.d/gost enable
	log "service enabled at boot"
fi

log "installation complete"
log "edit /etc/config/gost, then run: /etc/init.d/gost restart"
