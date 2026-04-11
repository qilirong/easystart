local map = Map("easystart", translate("WiFi设置"), translate("快速设置WiFi名字和密码，以及是否2.4G/5G合一"))

local section = map:section(TypedSection, "easystart", translate("WiFi基本设置"))
section.anonymous = true

-- 2.4G/5G合一选项
local wifi_unify = section:option(Flag, "wifi_unify", translate("2.4G/5G合一"))
wifi_unify.default = "1"

-- 统一WiFi名称和密码
local wifi_ssid = section:option(Value, "wifi_ssid", translate("WiFi名称"))
wifi_ssid.default = "OpenWrt"

local wifi_password = section:option(Value, "wifi_password", translate("WiFi密码"))
wifi_password.password = true
wifi_password.default = "password123"

-- 单独设置2.4G WiFi
local wifi_2g_ssid = section:option(Value, "wifi_2g_ssid", translate("2.4G WiFi名称"))
wifi_2g_ssid:depends("wifi_unify", "0")
wifi_2g_ssid.default = "OpenWrt_2.4G"

local wifi_2g_password = section:option(Value, "wifi_2g_password", translate("2.4G WiFi密码"))
wifi_2g_password.password = true
wifi_2g_password:depends("wifi_unify", "0")
wifi_2g_password.default = "password123"

-- 单独设置5G WiFi
local wifi_5g_ssid = section:option(Value, "wifi_5g_ssid", translate("5G WiFi名称"))
wifi_5g_ssid:depends("wifi_unify", "0")
wifi_5g_ssid.default = "OpenWrt_5G"

local wifi_5g_password = section:option(Value, "wifi_5g_password", translate("5G WiFi密码"))
wifi_5g_password.password = true
wifi_5g_password:depends("wifi_unify", "0")
wifi_5g_password.default = "password123"

return map