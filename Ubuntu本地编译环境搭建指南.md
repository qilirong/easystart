# Ubuntu本地编译环境搭建指南

## 系统要求

- Ubuntu 20.04 LTS 或更高版本
- 至少 4GB 内存（推荐 8GB 以上）
- 至少 50GB 磁盘空间
- 稳定的网络连接

## 步骤 1：准备工作

### 1.1 连接到Ubuntu服务器

使用SSH连接到Ubuntu服务器：

```bash
ssh haha@192.168.89.129
```

### 1.2 克隆项目代码

在Ubuntu服务器上克隆项目代码：

```bash
git clone https://github.com/qilirong/easystart.git
cd easystart
```

## 步骤 2：设置脚本权限

设置build-local.sh脚本的可执行权限：

```bash
chmod +x build-local.sh
```

## 步骤 3：运行编译脚本

执行build-local.sh脚本来构建插件：

```bash
./build-local.sh
```

脚本会自动执行以下操作：

1. 安装构建依赖
2. 添加交换空间（如果需要）
3. 清理并准备OpenWrt目录
4. 从OpenWrt官网下载预编译SDK
5. 提取并设置SDK
6. 添加插件到OpenWrt
7. 更新feeds并配置构建
8. 编译插件
9. 将编译产物复制到桌面目录
10. 清理临时文件

## 步骤 4：查看编译结果

编译完成后，编译产物会被复制到以下目录：

```
~/Desktop/openwrt-build-output/
```

您可以通过以下命令查看编译产物：

```bash
ls -la ~/Desktop/openwrt-build-output/
```

## 步骤 5：安装插件到路由器

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

## 脚本说明

### 脚本功能

- **自动安装依赖**：安装OpenWrt编译所需的所有依赖包
- **优化内存使用**：添加交换空间以避免内存不足
- **使用预编译SDK**：从OpenWrt官网下载预编译SDK，避免编译toolchain
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

## 总结

通过以上步骤，您可以在Ubuntu服务器上成功搭建OpenWrt插件编译环境，并使用预编译SDK编译luci-app-easystart插件。编译产物会自动复制到桌面目录，方便您安装到路由器上。

如果在编译过程中遇到任何问题，请参考故障排查部分进行解决。