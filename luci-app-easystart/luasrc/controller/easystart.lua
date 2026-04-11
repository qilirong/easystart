module('luci.controller.easystart', package.seeall)

function index()
    entry({'admin', 'easystart'}, firstchild(), _('便捷设置'), 10)
    entry({'admin', 'easystart', 'general'}, cbi('easystart/general'), _('联网设置'), 1)
    entry({'admin', 'easystart', 'ap'}, cbi('easystart/ap'), _('AP设置'), 2)
    entry({'admin', 'easystart', 'apply'}, call('action_apply')).dependent = false
    entry({'admin', 'easystart', 'status'}, call('action_status')).dependent = false
end

function action_apply()
    local mode = luci.http.formvalue('mode')
    local proto = luci.http.formvalue('proto')
    local username = luci.http.formvalue('username')
    local password = luci.http.formvalue('password')
    local ipaddr = luci.http.formvalue('ipaddr')
    local netmask = luci.http.formvalue('netmask')
    local gateway = luci.http.formvalue('gateway')
    local dns = luci.http.formvalue('dns')
    
    local cmd = '/usr/bin/easystart-switch.sh '
    
    if mode == 'main' then
        cmd = cmd .. 'main '
        if proto == 'pppoe' then
            cmd = cmd .. 'pppoe "' .. username .. '" "' .. password .. '"'
        elseif proto == 'static' then
            cmd = cmd .. 'static "' .. ipaddr .. '" "' .. netmask .. '" "' .. gateway .. '" "' .. dns .. '"'
        else
            cmd = cmd .. 'dhcp'
        end
    elseif mode == 'bypass' then
        cmd = cmd .. 'bypass "' .. ipaddr .. '" "' .. gateway .. '"'
    elseif mode == 'bridge' then
        cmd = cmd .. 'bridge'
    end
    
    local fp = io.popen(cmd .. ' 2>&1')
    local output = fp:read('*a')
    fp:close()
    
    luci.http.prepare_content('application/json')
    luci.http.write_json({ output = output })
end

function action_status()
    local status = {}
    
    -- 获取当前网络状态
    local lan_ip = luci.sys.exec('uci get network.lan.ipaddr 2>/dev/null')
    local wan_proto = luci.sys.exec('uci get network.wan.proto 2>/dev/null')
    
    status.lan_ip = string.gsub(lan_ip, '\n', '')
    status.wan_proto = string.gsub(wan_proto, '\n', '')
    
    -- 检测当前模式
    if wan_proto ~= '' then
        status.mode = 'main'
    else
        local dhcp_ignore = luci.sys.exec('uci get dhcp.lan.ignore 2>/dev/null')
        if dhcp_ignore == '1\n' then
            status.mode = 'bridge'
        else
            status.mode = 'bypass'
        end
    end
    
    luci.http.prepare_content('application/json')
    luci.http.write_json(status)
end
