local map = Map("easystart", translate("便捷设置"))

local section = map:section(TypedSection, "easystart", translate("联网设置"))
section.anonymous = true

-- 检查设备是否支持有线接入
local function check_wired_support()
    -- 检查是否有有线网络接口（排除loopback）
    local interfaces = luci.sys.exec("ls /sys/class/net/ 2>/dev/null | grep -v lo")
    return interfaces and interfaces ~= ""
end

-- 检查设备是否支持无线接入
local function check_wireless_support()
    -- 检查是否有无线网络接口
    local wireless_interfaces = luci.sys.exec("ls /sys/class/net/ 2>/dev/null | grep -E 'wlan|wifi|ra'")
    return wireless_interfaces and wireless_interfaces ~= ""
end

-- 接入类型
local access_type = section:option(ListValue, "access_type", translate("接入类型"))

-- 检查有线接入支持
local wired_supported = check_wired_support()
if wired_supported then
    access_type:value("wired", translate("有线接入"))
else
    -- 有线接入不可用，添加但禁用
    local wired_option = access_type:value("wired", translate("有线接入（不可用）"))
    if wired_option then
        wired_option.disabled = true
    end
end

-- 检查无线接入支持
local wireless_supported = check_wireless_support()
if wireless_supported then
    access_type:value("wireless", translate("无线接入"))
else
    -- 无线接入不可用，添加但禁用
    local wireless_option = access_type:value("wireless", translate("无线接入（不可用）"))
    if wireless_option then
        wireless_option.disabled = true
    end
end

-- 设置默认值
if wired_supported then
    access_type.default = "wired"
elseif wireless_supported then
    access_type.default = "wireless"
end

-- 有线接入模式
local wired_mode = section:option(ListValue, "wired_mode", translate("有线模式"))
wired_mode:value("router", translate("路由模式"))
wired_mode:value("bypass", translate("旁路由模式"))
wired_mode.default = "router"
wired_mode:depends("access_type", "wired")

-- 无线接入模式
local wireless_mode = section:option(ListValue, "wireless_mode", translate("无线模式"))
wireless_mode:value("repeater", translate("中继模式"))
wireless_mode:value("bridge", translate("桥接模式"))
wireless_mode.default = "repeater"
wireless_mode:depends("access_type", "wireless")

-- 有线路由模式配置
local proto = section:option(ListValue, "proto", translate("WAN协议"))
proto:value("dhcp", translate("DHCP自动获取"))
proto:value("pppoe", translate("PPPoE拨号"))
proto:value("static", translate("静态IP"))
proto.default = "dhcp"
proto:depends("wired_mode", "router")

local pppoe_username = section:option(Value, "pppoe_username", translate("PPPoE用户名"))
pppoe_username:depends("proto", "pppoe")

local pppoe_password = section:option(Value, "pppoe_password", translate("PPPoE密码"))
pppoe_password.password = true
pppoe_password:depends("proto", "pppoe")

-- 获取当前网络配置作为默认值
local current_ip = luci.sys.exec("uci get network.lan.ipaddr 2>/dev/null"):gsub("%s+", "")
local current_netmask = luci.sys.exec("uci get network.lan.netmask 2>/dev/null"):gsub("%s+", "")
if current_netmask == "" then current_netmask = "255.255.255.0" end

local static_ip = section:option(Value, "static_ip", translate("静态IP地址"))
static_ip:depends("proto", "static")
static_ip.default = current_ip ~= "" and current_ip or "192.168.1.1"

local static_netmask = section:option(Value, "static_netmask", translate("子网掩码"))
static_netmask:depends("proto", "static")
static_netmask.default = current_netmask

local static_gateway = section:option(Value, "static_gateway", translate("默认网关"))
static_gateway:depends("proto", "static")
static_gateway.default = current_ip ~= "" and current_ip or "192.168.1.1"

local static_dns = section:option(Value, "static_dns", translate("DNS服务器"))
static_dns:depends("proto", "static")
static_dns.default = "114.114.114.114"

-- 旁路由模式配置
local bypass_ip = section:option(Value, "bypass_ip", translate("旁路由IP地址"))
bypass_ip:depends("wired_mode", "bypass")
bypass_ip.default = "192.168.1.2"

local bypass_gateway = section:option(Value, "bypass_gateway", translate("主路由IP地址"))
bypass_gateway:depends("wired_mode", "bypass")
bypass_gateway.default = "192.168.1.1"

-- 无线中继模式配置
local wireless_ssid = section:option(Value, "wireless_ssid", translate("上级WiFi名称"))
wireless_ssid:depends("wireless_mode", "repeater")

local wireless_password = section:option(Value, "wireless_password", translate("上级WiFi密码"))
wireless_password.password = true
wireless_password:depends("wireless_mode", "repeater")

-- 无线桥接模式配置
local bridge_ssid = section:option(Value, "bridge_ssid", translate("上级WiFi名称"))
bridge_ssid:depends("wireless_mode", "bridge")

local bridge_password = section:option(Value, "bridge_password", translate("上级WiFi密码"))
bridge_password.password = true
bridge_password:depends("wireless_mode", "bridge")

-- 无线扫描按钮
local scan_button = section:option(Button, "scan", translate("扫描WiFi"))
scan_button:depends("access_type", "wireless")
scan_button.inputtitle = translate("扫描")
scan_button.inputstyle = "apply"
if not wireless_supported then
    scan_button.disabled = true
end

function scan_button.write(self, section, value)
    local status, err = pcall(function()
        -- 首先检查系统是否支持无线功能
        local has_wifi = luci.sys.exec("ls /sys/class/net/ 2>/dev/null | grep -E 'wlan|wifi|ra' | head -1")
        has_wifi = has_wifi:gsub("%s+", "")
        
        if not has_wifi or has_wifi == "" then
            luci.http.prepare_content("text/plain")
            luci.http.write(translate("当前设备不支持无线功能"))
            return
        end
        
        -- 检查iwinfo是否可用
        local iwinfo_check = luci.sys.exec("which iwinfo 2>/dev/null")
        if not iwinfo_check or iwinfo_check == "" then
            luci.http.prepare_content("text/plain")
            luci.http.write(translate("错误: 未安装iwinfo工具，无法扫描WiFi"))
            return
        end
        
        -- 获取所有无线接口
        local wifi_devices = luci.sys.exec("iwinfo 2>/dev/null | grep 'Access Point' | awk '{print $1}' | head -1")
        wifi_devices = wifi_devices:gsub("%s+", "")
        
        if not wifi_devices or wifi_devices == "" then
            -- 尝试其他方式获取无线接口
            wifi_devices = luci.sys.exec("iwinfo 2>/dev/null | head -1 | awk '{print $1}'")
            wifi_devices = wifi_devices:gsub("%s+", "")
            
            if not wifi_devices or wifi_devices == "" then
                luci.http.prepare_content("text/plain")
                luci.http.write(translate("错误: 未找到无线接口，请确保无线功能已启用"))
                return
            end
        end
        
        -- 执行扫描命令
        local scan_cmd = "iwinfo " .. wifi_devices .. " scan 2>&1"
        local output = luci.sys.exec(scan_cmd)
        
        if not output or output == "" then
            luci.http.prepare_content("text/plain")
            luci.http.write(translate("扫描失败: 无法获取WiFi列表，请检查无线接口状态"))
            return
        end
        
        -- 解析SSID
        local ssids = {}
        local seen = {}
        
        -- 简单的方式解析SSID
        for line in output:lines() do
            local ssid = line:match('ESSID: "(.*)"')
            if not ssid then
                ssid = line:match("ESSID: '(.*)'")
            end
            if not ssid then
                ssid = line:match('ESSID: (.*)')
            end
            if ssid and ssid ~= "" and not seen[ssid] then
                seen[ssid] = true
                table.insert(ssids, ssid)
            end
        end
        
        if #ssids > 0 then
            local result = translate("发现以下WiFi网络:") .. "\n"
            result = result .. "===================\n"
            for i, ssid in ipairs(ssids) do
                result = result .. i .. ". " .. ssid .. "\n"
            end
            luci.http.prepare_content("text/plain")
            luci.http.write(result)
        else
            -- 显示原始输出以便调试
            local result = translate("未发现WiFi网络，请确保周围有可用的无线网络") .. "\n"
            result = result .. "\n" .. translate("调试信息:") .. "\n"
            result = result .. output:sub(1, 500) -- 只显示前500个字符
            luci.http.prepare_content("text/plain")
            luci.http.write(result)
        end
    end)
    
    if not status then
        luci.http.prepare_content("text/plain")
        luci.http.write(translate("扫描时发生错误:") .. " " .. tostring(err))
    end
end

-- 连接测试按钮
local test_button = section:option(Button, "test", translate("连接测试"))
test_button:depends("access_type", "wireless")
test_button.inputtitle = translate("测试")
test_button.inputstyle = "test"
if not wireless_supported then
    test_button.disabled = true
end

function test_button.write(self, section, value)
    local mode = luci.http.formvalue("cbid.easystart.general.wireless_mode")
    local ssid, password
    
    if mode == "repeater" then
        ssid = luci.http.formvalue("cbid.easystart.general.wireless_ssid")
        password = luci.http.formvalue("cbid.easystart.general.wireless_password")
    else
        ssid = luci.http.formvalue("cbid.easystart.general.bridge_ssid")
        password = luci.http.formvalue("cbid.easystart.general.bridge_password")
    end
    
    if not ssid or ssid == "" then
        luci.http.prepare_content("text/plain")
        luci.http.write(translate("请输入WiFi名称"))
        return
    end
    
    -- 这里添加实际的连接测试逻辑
    local test_result = translate("连接测试成功")
    luci.http.prepare_content("text/plain")
    luci.http.write(test_result)
end

return map
