#!/bin/sh

# 简易设置 - 模式切换脚本

# 显示帮助信息
show_help() {
    echo "简易设置 - 模式切换脚本"
    echo "用法: $0 [模式] [参数]"
    echo "模式:"
    echo "  main [pppoe|static|dhcp] [参数]  - 传统路由模式"
    echo "  bypass [IP地址] [网关]          - 旁路由模式"
    echo "  bridge                          - 桥接模式"
    echo ""
    echo "示例:"
    echo "  $0 main dhcp                    - 传统路由模式，DHCP获取IP"
    echo "  $0 main pppoe 用户名 密码       - 传统路由模式，PPPoE拨号"
    echo "  $0 main static IP 子网掩码 网关 DNS - 传统路由模式，