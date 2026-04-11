#!/bin/bash

# 本地Ubuntu编译脚本
# 基于GitHub workflow逻辑，但在本地Ubuntu环境中运行
# 使用环境配置: .trae/rules/environment.md

set -e

echo "========================================"
echo "开始本地编译 luci-app-easystart 插件"
echo "========================================"
echo "使用环境: Ubuntu (IP: 192.168.89.129, 用户名: haha)"
echo "========================================"

# 检查是否在Ubuntu环境中运行
if [[ "$(lsb_release -si)" != "Ubuntu" ]]; then
    echo "错误: 此脚本仅在Ubuntu环境中运行"
    exit 1
fi

# 步骤1: 安装构建依赖
echo "步骤1: 安装构建依赖..."
# 尝试使用apt-get安装依赖，忽略错误继续执行
apt update 2>/dev/null || true
apt install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python3 make 2>/dev/null || true
apt install -y flex bison texinfo 2>/dev/null || true

echo "依赖安装完成（如果失败，请手动安装依赖）"

# 步骤2: 添加交换空间（可选但推荐）
echo "步骤2: 添加交换空间..."
# 尝试创建 2GB swap 文件，忽略错误继续执行
echo "尝试创建 2GB swap 文件..."
fallocate -l 2GB /swapfile 2>/dev/null || true
if [ -f /swapfile ]; then
  chmod 600 /swapfile 2>/dev/null || true
  mkswap /swapfile 2>/dev/null || true
  swapon /swapfile 2>/dev/null || true
  free -h
else
  echo "Swap 文件创建失败，继续执行..."
  free -h
fi
echo "交换空间设置完成"

# 步骤3: 准备OpenWrt目录（保留已有的环境）
echo "步骤3: 准备OpenWrt目录..."
# 只创建目录，不删除已有的内容，保留之前的环境
mkdir -p openwrt

echo "OpenWrt目录准备完成（保留已有的环境）"

# 步骤4: 使用本地预编译SDK（如果需要）
echo "步骤4: 提取预编译SDK..."
cd openwrt

# 检查SDK是否已经设置好
if [ -f "Makefile" ]; then
  echo "SDK已经存在，跳过提取步骤..."
else
  # 检查本地SDK文件是否存在
  if [ -f "../openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz" ]; then
    echo "使用本地SDK文件..."
    cp ../openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz .
    SDK_FILE="openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz"
    SDK_DIR="openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64"
  else
    echo "错误: 本地SDK文件不存在"
    exit 1
  fi

  # 解压SDK
  echo "解压SDK..."
  tar -xJf "$SDK_FILE"

  # 检查解压是否成功
  if [ ! -d "$SDK_DIR" ]; then
    echo "错误: 无法解压SDK"
    exit 1
  fi

  # 移动SDK内容到当前目录
  echo "移动SDK文件到当前目录..."
  mv "$SDK_DIR"/* .
  mv "$SDK_DIR"/.* . 2>/dev/null || true

  # 清理临时目录
  rm -rf "$SDK_DIR"
  rm -f "$SDK_FILE"

  # 检查SDK是否正确设置
  if [ ! -f "Makefile" ]; then
    echo "错误: SDK文件设置失败"
    exit 1
  fi

  # 查看当前目录结构
  echo "SDK设置完成。目录结构:"
  ls -la
fi

# 步骤5: 添加插件到OpenWrt（更新插件文件）
echo "步骤5: 添加插件到OpenWrt..."
mkdir -p package/luci-app-easystart
# 复制插件文件，覆盖已有的文件以确保使用最新版本
cp -r ../luci-app-easystart/* package/luci-app-easystart/

echo "插件添加完成（已更新到最新版本）"

# 步骤6: 更新feeds并配置构建
echo "步骤6: 更新feeds并配置构建..."

# 更新feeds
echo "更新feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 配置构建
echo "配置构建..."
echo "CONFIG_TARGET_x86=y" > .config
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_generic=y" >> .config
echo "CONFIG_PACKAGE_luci-app-easystart=y" >> .config
echo "CONFIG_CCACHE=n" >> .config
make defconfig

echo "构建配置完成"

# 步骤7: 编译插件
echo "步骤7: 编译插件..."

# 使用单线程编译，避免内存溢出
echo "使用预编译SDK编译插件..."
# 只编译插件及其依赖，不编译toolchain
make package/luci-app-easystart/compile -j1 V=s

# 检查编译是否成功
if [ $? -eq 0 ]; then
  echo "插件编译成功！"
else
  echo "插件编译失败，查看详细日志..."
  # 查看构建日志
  find . -name "*.log" -type f | xargs tail -n 100
  exit 1
fi

# 步骤8: 查看编译产物
echo "步骤8: 查看编译产物..."

# 创建bin/packages目录（如果不存在）
mkdir -p bin/packages

# 查找编译生成的IPK文件
echo "查找编译生成的IPK文件:"
find bin/packages -name "luci-app-easystart*.ipk" || echo "未找到编译产物"

# 复制编译产物到desktop目录
echo "复制编译产物到desktop目录..."
DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR/openwrt-build-output"
cp bin/packages/*/luci-app-easystart*.ipk "$DESKTOP_DIR/openwrt-build-output/" 2>/dev/null || true

echo "编译产物已复制到 $DESKTOP_DIR/openwrt-build-output/ 目录"

# 步骤9: 清理
echo "步骤9: 清理..."

# 关闭交换空间（如果创建了）
if [ -f /swapfile ]; then
  swapoff /swapfile 2>/dev/null || true
  rm -f /swapfile 2>/dev/null || true
  echo "交换空间已清理"
fi

echo "========================================"
echo "本地编译完成！"
echo "========================================"
echo "编译产物位于: $DESKTOP_DIR/openwrt-build-output/"
echo ""
echo "要安装插件到路由器，请执行:"
echo "scp "$DESKTOP_DIR/openwrt-build-output/luci-app-easystart*.ipk" root@192.168.89.128:/tmp/"
echo "然后登录路由器执行: opkg install /tmp/luci-app-easystart*.ipk"
echo "========================================"