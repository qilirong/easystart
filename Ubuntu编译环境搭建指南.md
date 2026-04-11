# Ubuntu 编译环境搭建指南

## 系统要求

- Ubuntu 20.04 LTS 或更高版本
- 至少 4GB 内存（推荐 8GB 以上）
- 至少 50GB 磁盘空间
- 稳定的网络连接

## 环境配置信息

### Ubuntu服务器
- IP：192.168.89.129
- 用户名：haha
- 密码：秘钥

### OpenWrt路由器
- IP：192.168.89.128
- 用户名：root
- 密码：秘钥

## 方法一：使用自动化脚本编译

### 步骤 1：连接到Ubuntu服务器

使用SSH连接到Ubuntu服务器：

```bash
ssh haha@192.168.89.129
```

### 步骤 2：克隆项目代码

在Ubuntu服务器上克隆项目代码：

```bash
git clone https://github.com/qilirong/easystart.git
cd easystart
```

### 步骤 3：设置脚本权限

设置build-local.sh脚本的可执行权限：

```bash
chmod +x build-local.sh
```

### 步骤 4：运行编译脚本

执行build-local.sh脚本来构建插件：

```bash
./build-local.sh
```

脚本会自动执行以下操作：

1. 安装构建依赖
2. 添加交换空间（如果需要）
3. 准备OpenWrt目录（保留已有的环境）
4. 使用本地预编译SDK（如果需要）
5. 添加插件到OpenWrt
6. 更新feeds并配置构建
7. 编译插件
8. 将编译产物复制到桌面目录
9. 清理临时文件

### 步骤 5：查看编译结果

编译完成后，编译产物会被复制到以下目录：

```
~/Desktop/openwrt-build-output/
```

您可以通过以下命令查看编译产物：

```bash
ls -la ~/Desktop/openwrt-build-output/
```

## 方法二：手动编译

### 步骤 1：更新系统

首先，更新系统到最新版本：

```bash
sudo apt update
sudo apt upgrade -y
```

### 步骤 2：安装构建依赖

安装 OpenWrt 编译所需的依赖包：

```bash
sudo apt install -y build-essential libncurses5-dev libncursesw5-dev zlib1g-dev gawk git gettext libssl-dev xsltproc wget unzip python3 make
sudo apt install -y flex bison texinfo
```

### 步骤 3：创建交换空间（可选但推荐）

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

### 步骤 4：获取 OpenWrt 源码

克隆 OpenWrt 23.05 分支源码：

```bash
git clone --depth 1 --branch openwrt-23.05 https://github.com/openwrt/openwrt.git
cd openwrt
```

### 步骤 5：更新 feeds

更新并安装 OpenWrt feeds：

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### 步骤 6：添加插件到源码

将 luci-app-easystart 插件复制到 OpenWrt 源码中：

```bash
# 假设插件在当前目录的 luci-app-easystart 文件夹中
mkdir -p package/luci-app-easystart
cp -r ../luci-app-easystart/* package/luci-app-easystart/
```

### 步骤 7：配置构建

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

### 步骤 8：编译插件

使用单线程编译插件及其依赖：

```bash
# 只编译插件，不编译整个固件
make package/luci-app-easystart/compile -j1 V=s
```

### 步骤 9：获取编译产物

编译完成后，IPK 文件会生成在 `bin/packages` 目录中：

```bash
find bin/packages -name "luci-app-easystart*.ipk"
```

## 安装插件到路由器

将编译好的插件安装到OpenWrt路由器：

```bash
# 将插件复制到路由器
scp ~/Desktop/openwrt-build-output/luci-app-easystart*.ipk root@192.168.89.128:/tmp/

# 登录路由器并安装
ssh root@192.168.89.128
opkg install /tmp/luci-app-easystart*.ipk
```

## 故障排查

### 1. 依赖安装失败

**症状**：执行脚本时依赖安装失败

**解决方法**：
- 检查网络连接
- 尝试手动更新软件包列表：
  ```bash
  sudo apt update
  ```

### 2. SDK下载失败

**症状**：无法从OpenWrt官网下载SDK

**解决方法**：
- 检查网络连接
- 尝试手动下载SDK：
  ```bash
  wget https://downloads.openwrt.org/releases/23.05.0/targets/x86/64/openwrt-sdk-23.05.0-x86-64_gcc-12.3.0_musl.Linux-x86_64.tar.xz
  ```

### 3. 编译失败

**症状**：编译过程中出现错误

**解决方法**：
- 查看详细的编译日志
- 确保系统有足够的内存和磁盘空间
- 检查插件代码是否有语法错误

### 4. 权限问题

**症状**：执行脚本时出现权限错误

**解决方法**：
- 确保脚本具有可执行权限：
  ```bash
  chmod +x build-local.sh
  ```
- 确保当前用户有足够的权限执行脚本

### 5. 内存不足

**症状**：编译过程中出现 "Out of memory" 错误

**解决方法**：
- 创建更大的交换空间
- 使用单线程编译 (`-j1`)
- 关闭其他占用内存的进程

### 6. 网络问题

**症状**：下载依赖时出现网络错误

**解决方法**：
- 检查网络连接
- 考虑使用代理服务器
- 手动下载缺失的文件到 `dl` 目录

## 脚本说明

### 脚本功能

- **自动安装依赖**：安装OpenWrt编译所需的所有依赖包
- **优化内存使用**：添加交换空间以避免内存不足
- **使用预编译SDK**：使用本地预编译SDK，避免编译toolchain
- **保留过程环境**：保留已有的环境，方便再次编译
- **自动配置构建**：自动配置构建参数，无需手动干预
- **详细日志输出**：提供详细的编译日志，便于排查问题
- **自动清理**：编译完成后自动清理临时文件

### 脚本参数

此脚本无需任何参数，直接执行即可。

### 输出目录

编译产物会被复制到以下目录：

```
~/Desktop/openwrt-build-output/
```

## 注意事项

- 编译过程可能需要较长时间，取决于系统性能
- 确保有足够的磁盘空间和内存
- 保持网络连接稳定
- 定期更新项目代码以获取最新的更改
- 使用预编译SDK可以显著减少编译时间和内存使用

## 总结

通过以上步骤，您可以在Ubuntu服务器上成功搭建OpenWrt插件编译环境，并编译luci-app-easystart插件。编译产物会自动复制到桌面目录，方便您安装到路由器上。

如果在编译过程中遇到任何问题，请参考故障排查部分进行解决。