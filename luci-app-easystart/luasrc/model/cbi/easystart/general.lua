m = Map("easystart", "简易设置")
m.description = "配置路由器工作模式，支持传统路由、旁路由和桥接模式"

-- 添加CSS样式
m.template = "easystart/general"

-- 主配置部分
s = m:section(TypedSection, "general")
s.anonymous = true

-- 模式选择
mode = s:option(ListValue, "mode", "工作模式")
mode:value("main", "传统路由模式")
mode:value("bypass", "旁路由模式")
mode:value("bridge", "桥接模式")
mode.default = "main"

-- 传统路由模式参数
main_section = s:option(Value, "main_section", "")
main_section.template = "easystart/main_section"
main_section:depends("mode", "main")

-- 旁路由模式参数
bypass_section = s:option(Value, "bypass_section", "")
bypass_section.template = "easystart/bypass_section"
bypass_section:depends("mode", "bypass")

-- 桥接模式参数
bridge_section = s:option(Value, "bridge_section", "")
bridge_section.template = "easystart/bridge_section"
bridge_section:depends("mode", "bridge")

-- 应用按钮
apply = s:option(Button, "apply", "应用配置")
apply.inputtitle = "应用"
apply.inputstyle = "apply"
apply.write = function()
    local mode = mode:formvalue(1)
    local proto = "dhcp"
    local username = ""
    local password = ""
    local ipaddr = ""
    local netmask = ""
    local gateway = ""
    local dns = ""
    
    if mode == "main" then
        proto = luci.http.formvalue("cbid.easystart.general.proto") or "dhcp"
        if proto == "pppoe" then
            username = luci.http.formvalue("cbid.easystart.general.username") or ""
            password = luci.http.formvalue("cbid.easystart.general.password") or ""
        elseif proto == "static" then
            ipaddr = luci.http.formvalue("cbid.easystart.general.ipaddr") or ""
            netmask = luci.http.formvalue("cbid.easystart.general.netmask") or ""
            gateway = luci.http.formvalue("cbid.easystart.general.gateway") or ""
            dns = luci.http.formvalue("cbid.easystart.general.dns") or ""
        end
    elseif mode == "bypass" then
        ipaddr = luci.http.formvalue("cbid.easystart.general.bypass_ip") or ""
        gateway = luci.http.formvalue("cbid.easystart.general.bypass_gateway") or ""
    end
    
    local cmd = "/usr/bin/easystart-switch.sh "
    
    if mode == "main" then
        cmd = cmd .. "main "
        if proto == "pppoe" then
            cmd = cmd .. "pppoe \"" .. username .. "\" \"" .. password .. "\""
        elseif proto == "static" then
            cmd = cmd .. "static \"" .. ipaddr .. "\" \"" .. netmask .. "\" \"" .. gateway .. "\" \"" .. dns .. "\""
        else
            cmd = cmd .. "dhcp"
        end
    elseif mode == "bypass" then
        cmd = cmd .. "bypass \"" .. ipaddr .. "\" \"" .. gateway .. "\""
    elseif mode == "bridge" then
        cmd = cmd .. "bridge"
    end
    
    local fp = io.popen(cmd .. " 2>&1")
    local output = fp:read("*a")
    fp:close()
    
    luci.http.redirect(luci.dispatcher.build_url("admin", "easystart", "general"))
end

return m