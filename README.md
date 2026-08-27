# openwrt-gost

OpenWrt 25.12 package for [GOST v3](https://github.com/go-gost/gost), initially
limited to aarch64 targets. The package installs the official statically linked
Linux arm64 release binary and provides a procd service with UCI-based
multi-instance supervision.

## Install

On a supported OpenWrt router, run:

```sh
wget -O /tmp/install-gost.sh https://raw.githubusercontent.com/eeelin/openwrt-gost/main/install.sh && sh /tmp/install-gost.sh
```

The installer queries GitHub for the latest stable release (drafts and
prereleases are excluded), verifies OpenWrt 25.12 and aarch64, checks the APK
against its accompanying `.sha256` release asset, installs or upgrades it, and
enables the init service at boot. To install without enabling the service:

```sh
sh /tmp/install-gost.sh --no-enable
```

## Build

Add this repository as a package feed or copy it into an OpenWrt 25.12 SDK's
`package/gost` directory. Then select and build it:

```sh
make menuconfig                 # Network -> Web Servers/Proxies -> gost
make package/gost/compile V=s
```

## Configure multiple instances

Each `config instance` section in `/etc/config/gost` becomes a separate procd
process. Section names must be unique.

Configuration-file instance:

```uci
config instance 'office'
	option enabled '1'
	option config '/etc/gost/office.yaml'
	option respawn '1'
```

Command-line instance:

```uci
config instance 'local_proxy'
	option enabled '1'
	list listen 'socks5://:1080'
	list listen 'http://:8080'
	list forward 'socks5://proxy.example:1080'
	option debug '1'
```

Supported options are `enabled`, `config`, `api`, `metrics`, `debug`, `trace`,
`user`, `group`, `respawn`, `respawn_threshold`, `respawn_timeout`, and
`respawn_retry`. Repeatable `listen`, `forward`, and `arg` lists map to `-L`,
`-F`, and literal extra command arguments respectively. Prefer native options
over `arg` where available.

Apply changes and inspect logs:

```sh
/etc/init.d/gost enable
/etc/init.d/gost restart
logread -e gost
```

GOST features such as TUN/TAP or transparent proxying may also require the
corresponding OpenWrt kernel modules and firewall configuration.
