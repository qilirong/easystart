#!/bin/bash

# 设置FORCE=1环境变量，解决文件系统大小写不敏感问题
export FORCE=1

echo "=== 开始编译 luci-app-easystart 插件 ==="

# 检查SDK文件是否存在
if [ ! -f "../openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz" ]; then
  echo "SDK文件不存在，从清华源下载..."
  wget -c https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.5/targets/x86/64/openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz -O ../openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz
  if [ $? -ne 0 ]; then
    echo "错误: SDK下载失败，请检查网络连接"
    exit 1
  fi
  echo "SDK下载完成"
fi

# 安装依赖（只在第一次运行时执行）
if [ ! -f "./deps_installed" ]; then
  echo "安装构建依赖..."
  sudo apt update
  sudo apt install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python3 make flex bison texinfo
  touch ./deps_installed
  echo "依赖安装完成"
else
  echo "依赖已安装，跳过安装步骤"
fi

mkdir -p openwrt
cd openwrt

# 检查SDK是否已经提取（检查关键目录是否存在）
if [ ! -d "staging_dir" ] || [ ! -d "target" ]; then
  echo "SDK不存在，开始提取SDK..."
  cp ../openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz .
  tar -xJf openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz
  # 只移动目录内的文件，不移动压缩包
  find openwrt-sdk-23.05.5-x86-64_gcc-12.3.0_musl.Linux-x86_64 -maxdepth 1 -not -name "*.tar.xz" -exec mv {} . \;
  # 保留SDK目录和压缩包，方便下次编译
  echo "SDK提取完成，保留过程文件"
else
  echo "SDK已经存在，跳过提取步骤"
fi

# 清理旧的package目录，确保使用最新文件
rm -rf package/luci-app-easystart
mkdir -p package/luci-app-easystart
cp -r ../luci-app-easystart/* package/luci-app-easystart/

# 检查feeds是否已经更新
if [ ! -f "./feeds_updated" ]; then
  echo "使用原始源更新feeds..."
  # 直接创建新的feeds.conf.default文件，使用原始的OpenWrt源
  echo "创建新的feeds.conf.default文件..."
  cat > feeds.conf.default << 'EOF'
src-git base https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/openwrt.git;openwrt-23.05
src-git packages https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/packages.git
src-git luci https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/luci.git
src-git routing https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/routing.git
src-git telephony https://mirrors.tuna.tsinghua.edu.cn/git/openwrt/telephony.git
EOF
  echo "新的feeds.conf.default文件创建完成"
  
  # 使用FORCE=1解决文件系统大小写不敏感问题
  FORCE=1 ./scripts/feeds update -a
  FORCE=1 ./scripts/feeds install -a
  touch ./feeds_updated
  echo "Feeds更新完成"
else
  echo "Feeds已更新，跳过更新步骤"
fi

# 检查配置文件是否已经生成
if [ ! -f "./config_generated" ]; then
  echo "生成配置文件..."
  echo "CONFIG_TARGET_x86=y" > .config
  echo "CONFIG_TARGET_x86_64=y" >> .config
  echo "CONFIG_TARGET_x86_64_generic=y" >> .config
  echo "CONFIG_PACKAGE_luci-app-easystart=y" >> .config
  echo "CONFIG_CCACHE=n" >> .config
  # 使用FORCE=1解决文件系统大小写不敏感问题
  make defconfig FORCE=1
  touch ./config_generated
  echo "配置文件生成完成"
else
  echo "配置文件已生成，跳过生成步骤"
fi

# 先清理，再编译，确保使用最新文件
echo "清理并编译插件..."
# 使用FORCE=1解决文件系统大小写不敏感问题
make package/luci-app-easystart/clean V=s FORCE=1
make package/luci-app-easystart/compile -j1 V=s FORCE=1

# 复制编译产物
mkdir -p ../output
cp -r bin/packages/*/luci-app-easystart*.ipk ../output/ 2>/dev/null || echo "No packages found"

echo "=== 编译完成 ==="
echo "编译产物已复制到 ../output/ 目录"
echo "过程文件已保留，下次编译将使用缓存以节省时间"
