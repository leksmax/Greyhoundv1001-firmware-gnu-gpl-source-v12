--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: samba.lua 6984 2011-04-13 15:14:42Z soma $
]]--

m = Map("firewall", translate('Remote Access'), translate("The remote management function allows you to designate a host from the Internet to have management/configuration access to the device from a remote site. Enter the designated host IP Address in the Host IP Address field. "))

s = m:section(NamedSection, 'remote', 'remote')
s.anonymous = true

remote_en = s:option(Flag, 'remote_en', 'Enable')
remote_en.rmempty = false
remote_en.default = m.uci:get('firewall', 'remote', 'remote_en') or '0'

remote_ipaddr = s:option(Value, 'remote_ip', 'Host Address')
remote_ipaddr.rmempty = true
remote_ipaddr.datatype = ipaddr
remote_ipaddr.default = m.uci:get('firewall', 'remote', 'remote_ip') or ''
remote_ipaddr:depends("remote_en", "1")

remote_port = s:option(Value, 'remote_port', 'Port')
remote_port.rmempty = true
remote_port.size = 3
remote_port.maxlength = 5
remote_port.datatype = "range(0,65535)"
remote_port.default = m.uci:get('firewall', 'remote', 'remote_port') or '8080'
remote_port:depends('remote_en', "1")

return m

--local _st                                                                                                                                                           
--        for i=1, 100 do                                                                                                                                                     
--        _st = scanlist(2)                                                                                                                                                   
--        if _st then                                                                                                                                                         
--            break                                                                                                                                                           
--        end                                                                                                                                                                 
--        end                                                                                                                                                                 
--                                                                                                                                                                            
--        rv = {                                                                                                                                                              
--                iw_mode = iw.mode,                                                                                                                                          
--                iw_type = iw.type,                                                                                                                                          
--                st  = _st                                                                                                                                                   
--        }
