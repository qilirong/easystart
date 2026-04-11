#!/bin/bash

echo "=== 开始编译 luci-app-easystart 插件 ==="

sudo apt update
sudo apt install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python3 make flex bison texinfo

mkdir -p openwrt
cd openwrt

# 检查SDK是否已经存在
if [ ! -f "Makefile" ]; then
  echo "SDK不存在，开始提取SDK..."
  cp ../openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz .
  tar -xJf openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz
  mv openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64/* .
  # 保留SDK目录和压缩包，方便下次编译
  echo "SDK提取完成，保留过程文件"
else
  echo "SDK已经存在，跳过提取步骤"
fi

mkdir -p package/luci-app-easystart
cp -r ../luci-app-easystart/* package/luci-app-easystart/

# 使用原始源更新feeds
echo "使用原始源更新feeds..."
# 直接创建新的feeds.conf.default文件，使用原始的OpenWrt源
echo "创建新的feeds.conf.default文件..."
cat > feeds.conf.default << 'EOF'
src-git base https://git.openwrt.org/openwrt/openwrt.git;openwrt-23.05
src-git packages https://git.openwrt.org/feed/packages.git
src-git luci https://git.openwrt.org/project/luci.git
src-git routing https://git.openwrt.org/feed/routing.git
src-git telephony https://git.openwrt.org/feed/telephony.git
EOF
echo "新的feeds.conf.default文件创建完成"

./scripts/feeds update -a
./scripts/feeds install -a

echo "CONFIG_TARGET_x86=y" > .config
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_generic=y" >> .config
echo "CONFIG_PACKAGE_luci-app-easystart=y" >> .config
echo "CONFIG_CCACHE=n" >> .config
make defconfig

make package/luci-app-easystart/compile -j1 V=s

mkdir -p ../output
cp -r bin/packages/*/luci-app-easystart*.ipk ../output/ 2>/dev/null || echo "No packages found"

echo "=== 编译完成 ==="
echo "编译产物已复制到 ~/easystart/output/ 目录"
