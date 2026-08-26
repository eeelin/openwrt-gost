include $(TOPDIR)/rules.mk

PKG_NAME:=gost
PKG_VERSION:=3.2.6
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/go-gost/gost/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=79874354530b899576dd4866d3b1400651d0b17c1e7a90ad30c44686a0642600

PKG_MAINTAINER:=claw-ruyi-homes
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/go-gost/gost
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/gost

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/gost
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=GO Simple Tunnel
  URL:=https://github.com/go-gost/gost
  DEPENDS:=$(GO_ARCH_DEPENDS) @aarch64 +ca-bundle
endef

define Package/gost/description
  GOST is a simple security tunnel written in Go. This package includes a
  procd service that can supervise multiple independent GOST instances.
endef

define Package/gost/conffiles
/etc/config/gost
/etc/gost/
endef

define Package/gost/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/gost $(1)/usr/bin/gost

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/gost.config $(1)/etc/config/gost

	$(INSTALL_DIR) $(1)/etc/gost
	$(INSTALL_CONF) ./files/example.yaml $(1)/etc/gost/example.yaml

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/gost.init $(1)/etc/init.d/gost
endef

$(eval $(call BuildPackage,gost))
