require 'luci.sys'
require 'luci.i18n'

-- 加载翻译
local _ = luci.i18n.translate

m = Map('router-mode', _('配置备份'), _('管理路由模式切换的配置备份'))

-- 备份列表
s = m:section(TypedSection, 'backup', _('备份文件'))
s.anonymous = true
s.addremove = false

local backup_dir = '/etc/config/backup'
local backups = {}

-- 读取备份文件
if luci.sys.call('test -d ' .. backup_dir) == 0 then
    local files = luci.sys.exec('ls -la ' .. backup_dir)
    for file in files:gmatch('([^\n]+)') do
        if file:match('network_.*') or file:match('dhcp_.*') or file:match('firewall_.*') then
            table.insert(backups, file)
        end
    end
end

if #backups > 0 then
    backup_list = s:option(DummyValue, 'backup_list', _('备份文件列表'))
    backup_list.value = function()
        local html = '<ul style="margin:0;padding:0;list-style:none;">'
        for _, file in ipairs(backups) do
            html = html .. '<li style="padding:5px;border-bottom:1px solid #eee;">' .. file .. '</li>'
        end
        html = html .. '</ul>'
        return html
    end
else
    no_backup = s:option(DummyValue, 'no_backup', _('无备份文件'))
    no_backup.value = _('当前没有备份文件')
end

-- 手动备份按钮
backup = s:option(Button, '_backup', _('手动备份配置'))
backup.inputtitle = _('备份')
backup.inputstyle = 'apply'

function backup.write(self, section, value)
    luci.sys.exec('/usr/bin/router-mode-switch.sh backup')
    luci.http.redirect(luci.dispatcher.build_url('admin', 'network', 'router-mode', 'backup'))
end

-- 清理备份按钮
clean = s:option(Button, '_clean', _('清理备份文件'))
clean.inputtitle = _('清理')
clean.inputstyle = 'reset'

function clean.write(self, section, value)
    luci.sys.exec('rm -f ' .. backup_dir .. '/*')
    luci.http.redirect(luci.dispatcher.build_url('admin', 'network', 'router-mode', 'backup'))
end

return m
