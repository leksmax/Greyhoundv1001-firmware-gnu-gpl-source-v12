include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

PKG_NAME:=senao-image-header
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/senao-image-header
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=SENAO Image Header
endef

define Package/senao-image-header/description
  Senao Image Header
endef

ifndef BUILD_DIR_DEV
  define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	ln -sf $(SN_CONFIGS_DIR)/firmwareconfig.h src/h/firmwareconfig.h
	$(CP) src/* $(PKG_BUILD_DIR)
  endef
endif

# use Build/Compile at include/package-defaults.mk
#

define Package/senao-image-header/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/header $(1)/bin/
endef

$(eval $(call BuildPackage,senao-image-header))
