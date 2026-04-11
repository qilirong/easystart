include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-easystart
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Qili Rong <qilirong@163.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-easystart
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Easy Start - 简易设置
  DESCRIPTION:=一键切换路由器工作模式，支持传统路由、旁路由、桥接模式
  DEPENDS:=+luci-base +luci-compat
  PKGARCH:=all
endef

define Build/Compile
  # 空实现，因为我们只需要安装文件
endef

define Package/luci-app-easystart/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/easystart
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/easystart
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/bin

	# 安装控制器文件
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/controller/easystart.lua $(1)/usr/lib/lua/luci/controller/

	# 安装CBI模型文件
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/model/cbi/easystart/general.lua $(1)/usr/lib/lua/luci/model/cbi/easystart/

	# 安装视图文件
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/view/easystart/*.htm $(1)/usr/lib/lua/luci/view/easystart/

	# 安装配置文件
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/root/etc/config/easystart $(1)/etc/config/

	# 安装脚本文件
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/root/usr/bin/easystart-switch.sh $(1)/usr/bin/
endef

$(eval $(call BuildPackage,luci-app-easystart))