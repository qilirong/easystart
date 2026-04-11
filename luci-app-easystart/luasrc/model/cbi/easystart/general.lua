local map = Map("easystart", translate("简易设置"), translate("配置路由器工作模式，支持传统路由、旁路由和桥接模式"))

local section = map:section(TypedSection, "general", translate("基本设置"))
section.anonymous = true

local mode = section:option(ListValue, "mode", translate("工作模式"))
mode:value("main", translate("传统路由模式"))
mode:value("bypass", translate("旁路由模式"))
mode:value("bridge", translate("桥接模式"))
mode.default = "main"

return map
