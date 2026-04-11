# Ubuntu 编译环境搭建指南

## 系统要求

- Ubuntu 20.04 LTS 或更高版本
- 至少 4GB 内存（推荐 8GB 以上）
- 至少 50GB 磁盘空间
- 稳定的网络连接

## 步骤 1：更新系统

首先，更新系统到最新版本：

```bash
sudo apt update
sudo apt upgrade -y
```

## 步骤 2：安装构建依赖

安装 OpenWrt 编译所需的依赖包：

```bash
sudo apt install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python3
```

安装额外的依赖包：

```bash
sudo apt install -y flex bison texinfo
```

## 步骤 3：创建交换空间（可选但推荐）

如果内存不足，创建交换空间以避免编译过程中的内存溢出：

```bash
# 创建 4GB 交换文件
sudo fallocate -l 4G /swapfile

# 设置权限
sudo chmod 600 /swapfile

# 格式化并启用交换文件
sudo mkswap /swapfile
sudo swapon /swapfile

# 设置开机自动启用
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 验证交换空间是否启用
free -h
```

## 步骤 4：获取 OpenWrt 源码

克隆 OpenWrt 23.05 分支源码：

```bash
git clone --depth 1 --branch openwrt-23.05 https://github.com/openwrt/openwrt.git
cd openwrt
```

## 步骤 5：更新 feeds

更新并安装 OpenWrt feeds：

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

## 步骤 6：添加插件到源码

将 luci-app-easystart 插件复制到 OpenWrt 源码中：

```bash
# 假设插件在当前目录的 luci-app-easystart 文件夹中
mkdir -p package/luci-app-easystart
cp -r ../luci-app-easystart/* package/luci-app-easystart/
```

## 步骤 7：配置构建

配置构建参数，选择目标架构和插件：

```bash
# 对于 x86_64 架构
echo "CONFIG_TARGET_x86=y" > .config
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_generic=y" >> .config
echo "CONFIG_PACKAGE_luci-app-easystart=y" >> .config

# 禁用 ccache 以节省内存
echo "CONFIG_CCACHE=n" >> .config

# 生成最终配置
make defconfig
```

## 步骤 8：编译插件

使用单线程编译插件及其依赖：

```bash
# 只编译插件，不编译整个固件
make package/luci-app-easystart/compile -j1 V=s
```

## 步骤 9：获取编译产物

编译完成后，IPK 文件会生成在 `bin/packages` 目录中：

```bash
find bin/packages -name "luci-app-easystart*.ipk"
```

## 步骤 10：安装插件到路由器

将编译好的 IPK 文件复制到路由器并安装：

```bash
# 假设路由器 IP 为 192.168.89.128
scp bin/packages/*/luci-app-easystart*.ipk root@192.168.89.128:/tmp/

# 登录路由器并安装
ssh root@192.168.89.128
opkg install /tmp/luci-app-easystart*.ipk
```

## 故障排查

### 1. 内存不足

**症状**：编译过程中出现 "Out of memory" 错误

**解决方法**：
- 创建更大的交换空间
- 使用单线程编译 (`-j1`)
- 关闭其他占用内存的进程

### 2. 依赖缺失

**症状**：编译过程中出现依赖错误

**解决方法**：
- 确保所有依赖包都已安装
- 运行 `./scripts/feeds update -a` 和 `./scripts/feeds install -a` 更新 feeds

### 3. 网络问题

**症状**：下载依赖时出现网络错误

**解决方法**：
- 检查网络连接
- 考虑使用代理服务器
- 手动下载缺失的文件到 `dl` 目录

### 4. 编译失败

**症状**：编译过程中出现错误

**解决方法**：
- 查看详细的编译日志
- 检查插件代码是否有语法错误
- 确保 Makefile 配置正确

## 自动化构建

为了方便重复构建，可以创建一个构建脚本：

```bash
#!/bin/bash

# 构建脚本

# 进入 OpenWrt 目录
cd openwrt || exit 1

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 配置构建
echo "CONFIG_TARGET_x86=y" > .config
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_generic=y" >> .config
echo "CONFIG_PACKAGE_luci-app-easystart=y" >> .config
echo "CONFIG_CCACHE=n" >> .config
make defconfig

# 编译插件
make package/luci-app-easystart/compile -j1 V=s

# 显示编译产物
find bin/packages -name "luci-app-easystart*.ipk"

# 复制到输出目录
mkdir -p ../output
cp bin/packages/*/luci-app-easystart*.ipk ../output/
echo "构建完成，产物已复制到 ../output/ 目录"
```

## 总结

通过以上步骤，您可以在 Ubuntu 系统上成功搭建 OpenWrt 插件编译环境，并编译 luci-app-easystart 插件。如果遇到问题，请参考故障排查部分进行解决。

## 注意事项

- 编译过程可能需要较长时间，取决于系统性能
- 确保有足够的磁盘空间和内存
- 保持网络连接稳定
- 定期更新 OpenWrt 源码以获取最新的依赖和修复