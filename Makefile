include $(TOPDIR)/rules.mk

PKG_NAME:=gost
PKG_VERSION:=3.2.6
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)_$(PKG_VERSION)_linux_arm64.tar.gz
PKG_SOURCE_URL:=https://github.com/go-gost/gost/releases/download/v$(PKG_VERSION)
PKG_HASH:=f674c8f4a033dc1dfd4f0d5e9602fbe5b0d0f81307bf3794f44b5b5d6d622eae

PKG_MAINTAINER:=claw-ruyi-homes
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/gost
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=GO Simple Tunnel
  URL:=https://github.com/go-gost/gost
  PKGARCH:=all
  DEPENDS:=@aarch64 +ca-bundle
endef

define Package/gost/description
  GOST is a simple security tunnel written in Go. This package includes a
  procd service that can supervise multiple independent GOST instances.
endef

define Package/gost/conffiles
/etc/config/gost
/etc/gost/
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/gost/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/gost $(1)/usr/bin/gost

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/gost.config $(1)/etc/config/gost

	$(INSTALL_DIR) $(1)/etc/gost
	$(INSTALL_CONF) ./files/example.yaml $(1)/etc/gost/example.yaml

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/gost.init $(1)/etc/init.d/gost
endef

$(eval $(call BuildPackage,gost))
