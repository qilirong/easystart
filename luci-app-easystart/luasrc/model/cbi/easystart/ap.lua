local map = Map("easystart", translate("便捷设置"))

local section = map:section(TypedSection, "easystart", translate("AP设置"))
section.anonymous = true

-- 无线AP开关
local ap_enable = section:option(Flag, "ap_enable", translate("启用无线AP"))
ap_enable.default = "1"

-- AP名称
local ap_ssid = section:option(Value, "ap_ssid", translate("AP名称"))
ap_ssid.default = "OpenWrt"
ap_ssid:depends("ap_enable", "1")

-- AP密码
local ap_password = section:option(Value, "ap_password", translate("AP密码"))
ap_password.password = true
ap_password.default = "password123"
ap_password:depends("ap_enable", "1")

-- 2.4G/5G聚合开关
local ap_unify = section:option(Flag, "ap_unify", translate("2.4G/5G聚合"))
ap_unify.default = "1"
ap_unify:depends("ap_enable", "1")

-- 分开设置（当不聚合时显示）
local ap_2g_ssid = section:option(Value, "ap_2g_ssid", translate("2.4G AP名称"))
ap_2g_ssid.default = "OpenWrt_2.4G"
ap_2g_ssid:depends("ap_unify", "0")

local ap_2g_password = section:option(Value, "ap_2g_password", translate("2.4G AP密码"))
ap_2g_password.password = true
ap_2g_password.default = "password123"
ap_2g_password:depends("ap_unify", "0")

local ap_5g_ssid = section:option(Value, "ap_5g_ssid", translate("5G AP名称"))
ap_5g_ssid.default = "OpenWrt_5G"
ap_5g_ssid:depends("ap_unify", "0")

local ap_5g_password = section:option(Value, "ap_5g_password", translate("5G AP密码"))
ap_5g_password.password = true
ap_5g_password.default = "password123"
ap_5g_password:depends("ap_unify", "0")

return map
