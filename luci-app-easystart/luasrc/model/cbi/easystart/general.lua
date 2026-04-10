require 'luci.sys'
require 'luci.http'
require 'luci.i18n'

-- 加载翻译
local _ = luci.i18n.translate

m = Map('easystart', _('简易设置'), _('一键切换路由器工作模式，支持传统路由、旁路由、桥接模式'))

-- 状态信息
s = m:section(TypedSection, 'general', _('当前状态'))
s.anonymous = true

current_mode = s:option(DummyValue, 'current_mode', _('当前工作模式'))
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

lan_ip = s:option(DummyValue, 'lan_ip', _('内网 IP'))
lan_ip.value = function()
    local ip = luci.sys.exec('uci get network.lan.ipaddr 2>/dev/null')
    return string.gsub(ip, '\n', '')
end

-- 模式选择
mode = m:section(TypedSection, 'general', _('模式选择'))
mode.anonymous = true

mode_type = mode:option(ListValue, 'type', _('工作模式'))
mode_type:value('main', _('传统路由模式（主路由）'))
mode_type:value('bypass', _('旁路由模式'))
mode_type:value('bridge', _('桥接模式（AP/交换机）'))
mode_type.default = 'main'

-- 传统路由模式参数
main_proto = mode:option(ListValue, 'main_proto', _('上网方式'))
main_proto:depends('type', 'main')
main_proto:value('dhcp', _('动态 IP'))
main_proto:value('pppoe', _('PPPoE 拨号'))
main_proto:value('static', _('静态 IP'))
main_proto.default = 'dhcp'

pppoe_username = mode:option(Value, 'pppoe_username', _('PPPoE 账号'))
pppoe_username:depends('main_proto', 'pppoe')

pppoe_password = mode:option(Value, 'pppoe_password', _('PPPoE 密码'))
pppoe_password:depends('main_proto', 'pppoe')
pppoe_password.password = true

static_ip = mode:option(Value, 'static_ip', _('静态 IP 地址'))
static_ip:depends('main_proto', 'static')
static_ip.default = '192.168.1.1'

static_netmask = mode:option(Value, 'static_netmask', _('子网掩码'))
static_netmask:depends('main_proto', 'static')
static_netmask.default = '255.255.255.0'

static_gateway = mode:option(Value, 'static_gateway', _('默认网关'))
static_gateway:depends('main_proto', 'static')
static_gateway.default = '192.168.1.1'

static_dns = mode:option(Value, 'static_dns', _('DNS 服务器'))
static_dns:depends('main_proto', 'static')
static_dns.default = '114.114.114.114'

-- 旁路由模式参数
bypass_ip = mode:option(Value, 'bypass_ip', _('旁路由 IP 地址'))
bypass_ip:depends('type', 'bypass')
bypass_ip.default = '192.168.1.2'

bypass_gateway = mode:option(Value, 'bypass_gateway', _('主路由 IP 地址'))
bypass_gateway:depends('type', 'bypass')
bypass_gateway.default = '192.168.1.1'

-- 应用按钮
apply = mode:option(Button, '_apply', _('一键应用配置'))
apply.inputtitle = _('应用')
apply.inputstyle = 'apply'

function apply.write(self, section, value)
    local mode = mode_type:formvalue(section)
    local proto = main_proto:formvalue(section)
    local username = pppoe_username:formvalue(section)
    local password = pppoe_password:formvalue(section)
    local ipaddr = ''
    local netmask = ''
    local gateway = ''
    local dns = ''
    
    if mode == 'main' then
        if proto == 'static' then
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
    local data = { mode = mode, proto = proto, username = username, password = password, ipaddr = ipaddr, netmask = netmask, gateway = gateway, dns = dns }
    
    luci.http.redirect(url .. '?' .. luci.http.build_query(data))
end

-- 恢复默认配置按钮
restore = mode:option(Button, '_restore', _('恢复默认配置'))
restore.inputtitle = _('恢复')
restore.inputstyle = 'reset'

function restore.write(self, section, value)
    local url = '/cgi-bin/luci/admin/easystart/apply?mode=restore'
    luci.http.redirect(url)
end

return m
