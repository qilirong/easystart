#!/bin/bash

# 进入openwrt目录
cd "$(dirname "$0")/../openwrt"

# 使用清华源更新feeds
cat > feeds.conf.default << 'EOF'
src-git base https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/openwrt.git;openwrt-23.05
src-git packages https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/packages.git
src-git luci https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/luci.git
src-git routing https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/routing.git
src-git telephony https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/telephony.git
EOF

# 更新feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 配置构建
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_mt7622=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7622_DEVICE_cudy_tr3000=y" >> .config
echo "CONFIG_PACKAGE_luci-app-easystart=y" >> .config
echo "CONFIG_CCACHE=n" >> .config
make defconfig
