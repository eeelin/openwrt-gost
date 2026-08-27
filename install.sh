#!/bin/sh

set -eu

REPOSITORY="eeelin/openwrt-gost"
ENABLE_SERVICE=1

usage() {
	cat <<EOF
Usage: install.sh [--no-enable]

Install the latest stable openwrt-gost release on OpenWrt 25.12 aarch64.

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
command -v jsonfilter >/dev/null 2>&1 || die "jsonfilter is required"

tmpdir="$(mktemp -d /tmp/openwrt-gost.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

release_api="https://api.github.com/repos/${REPOSITORY}/releases/latest"
log "checking the latest stable release"
download "$release_api" "$tmpdir/release.json" || die "failed to query $release_api"

release_tag="$(jsonfilter -i "$tmpdir/release.json" -e '@.tag_name')"
[ -n "$release_tag" ] || die "latest release response does not contain a tag"

package_url=""
checksum_url=""
asset_urls="$(jsonfilter -i "$tmpdir/release.json" -e '@.assets[*].browser_download_url')"
for asset_url in $asset_urls; do
	case "$asset_url" in
		*.apk)
			[ -z "$package_url" ] || die "release $release_tag contains multiple APK files"
			package_url="$asset_url"
			;;
		*.apk.sha256)
			[ -z "$checksum_url" ] || die "release $release_tag contains multiple APK checksum files"
			checksum_url="$asset_url"
			;;
	esac
done

[ -n "$package_url" ] || die "release $release_tag does not contain an APK"
[ -n "$checksum_url" ] || die "release $release_tag does not contain an APK checksum"

package="${package_url##*/}"
checksum="${checksum_url##*/}"
log "latest stable release is ${release_tag}"
log "downloading ${package}"
download "$package_url" "$tmpdir/$package" || die "failed to download $package_url"
download "$checksum_url" "$tmpdir/$checksum" || die "failed to download $checksum_url"

expected_sha256="$(awk 'NF { print $1; exit }' "$tmpdir/$checksum")"
actual_sha256="$(sha256sum "$tmpdir/$package" | awk '{ print $1 }')"
[ -n "$expected_sha256" ] || die "checksum file is empty"
[ "$actual_sha256" = "$expected_sha256" ] || \
	die "checksum mismatch: expected $expected_sha256, got $actual_sha256"
log "checksum verified"

log "installing ${package}"
apk add --allow-untrusted "$tmpdir/$package"

if [ "$ENABLE_SERVICE" -eq 1 ]; then
	/etc/init.d/gost enable
	log "service enabled at boot"
fi

log "installation complete"
log "edit /etc/config/gost, then run: /etc/init.d/gost restart"
