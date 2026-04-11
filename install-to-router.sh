#!/bin/bash

# 配置信息
ROUTER_IP="192.168.89.128"
ROUTER_USER="root"
PACKAGE_NAME="luci-app-easystart"
PACKAGE_FILE="output/luci-app-easystart_1.0-21_all.ipk"

echo "=== 开始安装插件到路由器 ==="
echo "路由器IP: ${ROUTER_IP}"
echo "用户名: ${ROUTER_USER}"

# 检查IPK文件是否存在
if [ ! -f "${PACKAGE_FILE}" ]; then
    echo "错误: 找不到IPK文件 ${PACKAGE_FILE}"
    echo "请先运行 build-wsl.sh 编译插件"
    exit 1
fi

# 步骤1: 卸载旧版本（如果存在）
echo ""
echo "1. 检查并卸载旧版本..."
ssh -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "opkg list-installed | grep -q ${PACKAGE_NAME}"
if [ $? -eq 0 ]; then
    echo "   发现旧版本，正在卸载..."
    ssh -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "opkg remove ${PACKAGE_NAME}"
    if [ $? -eq 0 ]; then
        echo "   旧版本卸载成功"
    else
        echo "   警告: 卸载可能失败，继续安装"
    fi
else
    echo "   未发现旧版本"
fi

# 步骤2: 上传IPK文件
echo ""
echo "2. 上传IPK文件到路由器..."
scp -o StrictHostKeyChecking=no ${PACKAGE_FILE} ${ROUTER_USER}@${ROUTER_IP}:/tmp/luci-app-easystart_1.0-21_all.ipk
if [ $? -ne 0 ]; then
    echo "错误: 上传IPK文件失败"
    exit 1
fi
echo "   上传成功"

# 步骤3: 安装新版本
echo ""
echo "3. 安装新版本..."
ssh -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "opkg install /tmp/luci-app-easystart_1.0-21_all.ipk"
if [ $? -ne 0 ]; then
    echo "错误: 安装失败"
    exit 1
fi
echo "   安装成功"

# 步骤4: 重启LuCI
echo ""
echo "4. 重启LuCI服务..."
ssh -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "/etc/init.d/uhttpd restart"
echo "   LuCI已重启"

# 步骤5: 清理临时文件
echo ""
echo "5. 清理临时文件..."
ssh -o StrictHostKeyChecking=no ${ROUTER_USER}@${ROUTER_IP} "rm -f /tmp/luci-app-easystart_1.0-21_all.ipk"
echo "   清理完成"

echo ""
echo "=== 安装完成 ==="
echo "请访问 http://${ROUTER_IP}/ 查看'简易设置'菜单"
