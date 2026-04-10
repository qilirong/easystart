include $(TOPDIR)/rules.mk

LUCI_TITLE:=简易设置
LUCI_DESCRIPTION:=一键切换路由器工作模式，支持传统路由、旁路由、桥接模式
LUCI_DEPENDS:=+luci-base +luci-compat
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-easystart
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt build system will take care of the rest
