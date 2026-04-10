#!/bin/sh

# OpenWrt 路由模式切换脚本
# 支持：传统路由模式、旁路由模式、桥接模式

BACKUP_DIR="/etc/config/backup"
CONFIG_FILES="network dhcp firewall"

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NC="\033[0m"

# 日志函数
log() {
    echo "${BLUE}[Router Mode Switch]${NC} $1"
}

log_error() {
    echo "${RED}[Error]${NC} $1"
}

log_success() {
    echo "${GREEN}[Success]${NC} $1"
}

log_warning() {
    echo "${YELLOW}[Warning]${NC} $1"
}

# 备份配置
backup_config() {
    log "备份当前配置..."
    mkdir -p "$BACKUP_DIR"
    
    for file in $CONFIG_FILES; do
        if [ -f "/etc/config/$file" ]; then
            cp "/etc/config/$file" "$BACKUP_DIR/${file}_$(date +%Y%m%d_%H%M%S)"
            log_success "备份 $file 成功"
        fi
    done
}

# 恢复默认配置
restore_default() {
    log "恢复默认配置..."
    
    # 恢复网络默认配置
    uci set network.lan=interface
    uci set network.lan.ifname='eth0'
    uci set network.lan.proto='static'
    uci set network.lan.ipaddr='192.168.1.1'
    uci set network.lan.netmask='255.255.255.0'
    uci set network.lan.ip6assign='60'
    
    uci set network.wan=interface
    uci set network.wan.ifname='eth1'
    uci set network.wan.proto='dhcp'
    
    uci set network.wan6=interface
    uci set network.wan6.ifname='eth1'
    uci set network.wan6.proto='dhcpv6'
    
    # 恢复 DHCP 默认配置
    uci set dhcp.lan=dhcp
    uci set dhcp.lan.interface='lan'
    uci set dhcp.lan.start='100'
    uci set dhcp.lan.limit='150'
    uci set dhcp.lan.leasetime='12h'
    
    uci set dhcp.wan=dhcp
    uci set dhcp.wan.interface='wan'
    uci set dhcp.wan.ignore='1'
    
    # 恢复防火墙默认配置
    uci set firewall.@zone[0]=zone
    uci set firewall.@zone[0].name='lan'
    uci set firewall.@zone[0].network='lan'
    uci set firewall.@zone[0].input='ACCEPT'
    uci set firewall.@zone[0].output='ACCEPT'
    uci set firewall.@zone[0].forward='ACCEPT'
    
    uci set firewall.@zone[1]=zone
    uci set firewall.@zone[1].name='wan'
    uci set firewall.@zone[1].network='wan wan6'
    uci set firewall.@zone[1].input='REJECT'
    uci set firewall.@zone[1].output='ACCEPT'
    uci set firewall.@zone[1].forward='REJECT'
    uci set firewall.@zone[1].masq='1'
    uci set firewall.@zone[1].mtu_fix='1'
    
    uci set firewall.@forwarding[0]=forwarding
    uci set firewall.@forwarding[0].src='lan'
    uci set firewall.@forwarding[0].dest='wan'
    
    uci commit
    log_success "恢复默认配置成功"
}

# 应用配置并重启服务
apply_config() {
    log "应用配置..."
    uci commit
    
    log "重启网络服务..."
    /etc/init.d/network restart
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart
    
    log_success "配置已应用，网络服务已重启"
}

# 传统路由模式（主路由）
setup_main_router() {
    log "配置传统路由模式..."
    
    # 配置网络
    uci set network.lan=interface
    uci set network.lan.ifname='eth0'
    uci set network.lan.proto='static'
    uci set network.lan.ipaddr='192.168.1.1'
    uci set network.lan.netmask='255.255.255.0'
    
    uci set network.wan=interface
    uci set network.wan.ifname='eth1'
    uci set network.wan.proto="$1"
    
    if [ "$1" = "pppoe" ]; then
        uci set network.wan.username="$2"
        uci set network.wan.password="$3"
    elif [ "$1" = "static" ]; then
        uci set network.wan.ipaddr="$2"
        uci set network.wan.netmask="$3"
        uci set network.wan.gateway="$4"
        uci set network.wan.dns="$5"
    fi
    
    # 配置 DHCP
    uci set dhcp.lan=dhcp
    uci set dhcp.lan.interface='lan'
    uci set dhcp.lan.start='100'
    uci set dhcp.lan.limit='150'
    uci set dhcp.lan.leasetime='12h'
    
    uci set dhcp.wan=dhcp
    uci set dhcp.wan.interface='wan'
    uci set dhcp.wan.ignore='1'
    
    # 配置防火墙
    uci set firewall.@zone[0]=zone
    uci set firewall.@zone[0].name='lan'
    uci set firewall.@zone[0].network='lan'
    uci set firewall.@zone[0].input='ACCEPT'
    uci set firewall.@zone[0].output='ACCEPT'
    uci set firewall.@zone[0].forward='ACCEPT'
    
    uci set firewall.@zone[1]=zone
    uci set firewall.@zone[1].name='wan'
    uci set firewall.@zone[1].network='wan wan6'
    uci set firewall.@zone[1].input='REJECT'
    uci set firewall.@zone[1].output='ACCEPT'
    uci set firewall.@zone[1].forward='REJECT'
    uci set firewall.@zone[1].masq='1'
    
    uci set firewall.@forwarding[0]=forwarding
    uci set firewall.@forwarding[0].src='lan'
    uci set firewall.@forwarding[0].dest='wan'
    
    apply_config
    log_success "传统路由模式配置完成"
}

# 旁路由模式
setup旁路_router() {
    log "配置旁路由模式..."
    
    # 配置网络
    uci set network.lan=interface
    uci set network.lan.ifname='eth0 eth1'
    uci set network.lan.proto='static'
    uci set network.lan.ipaddr="$1"
    uci set network.lan.netmask='255.255.255.0'
    uci set network.lan.gateway="$2"
    uci set network.lan.dns="$1"
    
    # 删除 WAN 接口
    uci delete network.wan
    uci delete network.wan6
    
    # 配置 DHCP
    uci set dhcp.lan=dhcp
    uci set dhcp.lan.interface='lan'
    uci set dhcp.lan.start='100'
    uci set dhcp.lan.limit='150'
    uci set dhcp.lan.leasetime='12h'
    uci set dhcp.lan.dhcp_option='3,'"$1"' 6,'"$1"''
    
    # 配置防火墙
    uci set firewall.@zone[0]=zone
    uci set firewall.@zone[0].name='lan'
    uci set firewall.@zone[0].network='lan'
    uci set firewall.@zone[0].input='ACCEPT'
    uci set firewall.@zone[0].output='ACCEPT'
    uci set firewall.@zone[0].forward='ACCEPT'
    
    # 删除 WAN 区域
    uci delete firewall.@zone[1]
    uci delete firewall.@forwarding[0]
    
    # 启用 IP 转发
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-ipforward.conf
    sysctl -p /etc/sysctl.d/99-ipforward.conf
    
    apply_config
    log_warning "旁路由模式配置完成，请关闭主路由的 DHCP 服务器以避免冲突"
}

# 桥接模式（AP/交换机）
setup_bridge_mode() {
    log "配置桥接模式..."
    
    # 创建桥接接口
    uci set network.@device[0]=device
    uci set network.@device[0].name='br-lan'
    uci set network.@device[0].type='bridge'
    uci set network.@device[0].ports='eth0 eth1'
    
    # 配置网络
    uci set network.lan=interface
    uci set network.lan.device='br-lan'
    uci set network.lan.proto='dhcp'
    
    # 删除 WAN 接口
    uci delete network.wan
    uci delete network.wan6
    
    # 关闭 DHCP
    uci set dhcp.lan=dhcp
    uci set dhcp.lan.interface='lan'
    uci set dhcp.lan.ignore='1'
    
    # 配置防火墙
    uci set firewall.@zone[0]=zone
    uci set firewall.@zone[0].name='lan'
    uci set firewall.@zone[0].network='lan'
    uci set firewall.@zone[0].input='ACCEPT'
    uci set firewall.@zone[0].output='ACCEPT'
    uci set firewall.@zone[0].forward='ACCEPT'
    
    # 删除 WAN 区域和转发规则
    uci delete firewall.@zone[1]
    uci delete firewall.@forwarding[0]
    
    apply_config
    log_success "桥接模式配置完成，设备已变为纯 AP/交换机"
}

# 主函数
main() {
    case "$1" in
        backup)
            backup_config
            ;;
        restore)
            restore_default
            ;;
        main)
            backup_config
            setup_main_router "$2" "$3" "$4" "$5" "$6" "$7"
            ;;
        bypass)
            backup_config
            setup旁路_router "$2" "$3"
            ;;
        bridge)
            backup_config
            setup_bridge_mode
            ;;
        *)
            echo "用法: $0 {backup|restore|main|bypass|bridge}"
            echo "  backup: 备份当前配置"
            echo "  restore: 恢复默认配置"
            echo "  main <proto> [params]: 配置传统路由模式"
            echo "    proto: pppoe|dhcp|static"
            echo "    pppoe params: username password"
            echo "    static params: ipaddr netmask gateway dns"
            echo "  bypass <ipaddr> <gateway>: 配置旁路由模式"
            echo "  bridge: 配置桥接模式"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
