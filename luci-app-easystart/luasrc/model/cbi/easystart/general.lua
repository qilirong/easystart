require 'luci.sys'
require 'luci.http'
require 'luci.i18n'
require 'luci.jsonc'

-- 加载翻译
local _ = luci.i18n.translate

-- 创建主配置映射
local m = Map('easystart', _('简易设置'), _('一键切换路由器工作模式，支持传统路由、旁路由、桥接模式'))

-- 状态信息部分
local s = m:section(TypedSection, 'general', _('当前状态'))
s.anonymous = true

-- 当前工作模式
local current_mode = s:option(DummyValue, 'current_mode', _('当前工作模式'))
current_mode.value = function()
    local status = luci.http.getenv('REQUEST_URI'):match('/admin/easystart/status')
    if status then
        local data = luci.sys.exec('curl -s http://localhost/cgi-bin/luci/admin/easystart/status')
        local json = luci.jsonc.parse(data)
        if json and json.mode then
            if json.mode == 'main' then return _('传统路由模式')
            elseif json.mode == 'bypass' then return _('旁路由模式')
            elseif json.mode == 'bridge' then return _('桥接模式')
            else return _('未知模式')
            end
        end
    end
    return _('检测中...')
end

-- 内网 IP
local lan_ip = s:option(DummyValue, 'lan_ip', _('内网 IP'))
lan_ip.value = function()
    local ip = luci.sys.exec('uci get network.lan.ipaddr 2>/dev/null')
    return string.gsub(ip, '\n', '')
end

-- 模式选择部分
local mode_section = m:section(TypedSection, 'general', _('模式选择'))
mode_section.anonymous = true

-- 工作模式选择
local mode_type = mode_section:option(ListValue, 'mode', _('工作模式'))
mode_type:value('main', _('传统路由模式（主路由）'))
mode_type:value('bypass', _('旁路由模式'))
mode_type:value('bridge', _('桥接模式（AP/交换机）'))
mode_type.default = 'main'

-- 传统路由模式参数
local proto = mode_section:option(ListValue, 'proto', _('上网方式'))
proto:depends('mode', 'main')
proto:value('dhcp', _('动态 IP'))
proto:value('pppoe', _('PPPoE 拨号'))
proto:value('static', _('静态 IP'))
proto.default = 'dhcp'

local pppoe_username = mode_section:option(Value, 'pppoe_username', _('PPPoE 账号'))
pppoe_username:depends('proto', 'pppoe')

local pppoe_password = mode_section:option(Value, 'pppoe_password', _('PPPoE 密码'))
pppoe_password:depends('proto', 'pppoe')
pppoe_password.password = true

local static_ip = mode_section:option(Value, 'static_ip', _('静态 IP 地址'))
static_ip:depends('proto', 'static')
static_ip.default = '192.168.1.1'

local static_netmask = mode_section:option(Value, 'static_netmask', _('子网掩码'))
static_netmask:depends('proto', 'static')
static_netmask.default = '255.255.255.0'

local static_gateway = mode_section:option(Value, 'static_gateway', _('默认网关'))
static_gateway:depends('proto', 'static')
static_gateway.default = '192.168.1.1'

local static_dns = mode_section:option(Value, 'static_dns', _('DNS 服务器'))
static_dns:depends('proto', 'static')
static_dns.default = '114.114.114.114'

-- 旁路由模式参数
local bypass_ip = mode_section:option(Value, 'bypass_ip', _('旁路由 IP 地址'))
bypass_ip:depends('mode', 'bypass')
bypass_ip.default = '192.168.1.2'

local bypass_gateway = mode_section:option(Value, 'bypass_gateway', _('主路由 IP 地址'))
bypass_gateway:depends('mode', 'bypass')
bypass_gateway.default = '192.168.1.1'

-- 应用按钮
local apply = mode_section:option(Button, '_apply', _('一键应用配置'))
apply.inputtitle = _('应用')
apply.inputstyle = 'apply'

function apply.write(self, section, value)
    local mode = mode_type:formvalue(section)
    local proto_val = proto:formvalue(section)
    local username = pppoe_username:formvalue(section)
    local password = pppoe_password:formvalue(section)
    local ipaddr = ''
    local netmask = ''
    local gateway = ''
    local dns = ''
    
    if mode == 'main' then
        if proto_val == 'static' then
            ipaddr = static_ip:formvalue(section)
            netmask = static_netmask:formvalue(section)
            gateway = static_gateway:formvalue(section)
            dns = static_dns:formvalue(section)
        end
    elseif mode == 'bypass' then
        ipaddr = bypass_ip:formvalue(section)
        gateway = bypass_gateway:formvalue(section)
    end
    
    -- 调用后端脚本
    local url = '/cgi-bin/luci/admin/easystart/apply'
    local data = { mode = mode, proto = proto_val, username = username, password = password, ipaddr = ipaddr, netmask = netmask, gateway = gateway, dns = dns }
    
    luci.http.redirect(url .. '?' .. luci.http.build_query(data))
end

-- 恢复默认配置按钮
local restore = mode_section:option(Button, '_restore', _('恢复默认配置'))
restore.inputtitle = _('恢复')
restore.inputstyle = 'reset'

function restore.write(self, section, value)
    local url = '/cgi-bin/luci/admin/easystart/apply?mode=restore'
    luci.http.redirect(url)
end

return m
