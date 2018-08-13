--[[
LuCI - Lua Configuration Interface

Copyright 2011-2012 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--
local m2,s2,net = ...
local s3, server, username, password, server, hostname, ipaddr, netmask, connectionid, mtu, connectionType, dns, idletime, connect, unconnect

hostname = s2:option(Value, "hostname",
	translate("Hostname"))
local uci = luci.model.uci.cursor()
ipaddr = s2:option(Value, "ipaddr", translate("IP address"))
ipaddr.datatype = "ip4addr"


netmask = s2:option(Value, "netmask", translate("Subnet Mask"))
netmask.datatype = "ip4addr"
netmask:value("255.255.255.0")
netmask:value("255.255.0.0")
netmask:value("255.0.0.0")

gateway = s2:option(Value, "gateway", translate("Default Gateway"))
gateway.datatype = "ip4addr"


s3 = m2:section(NamedSection, "pptp", "interface","")
s3.addremove = false

username = s3:option(Value, "username", translate("Username"))
username.datatype = "maxlength(64)"

password = s3:option(Value, "password", translate("Password"))
password.password = true
password.datatype = "maxlength(64)"

server = s3:option(Value, "server", translate("PPTP Gateway"))
server.datatype = "ip4addr"

connectionid = s3:option(Value, "connectionid", translate("Connect ID"))
connectionid.placeholder = "0"
connectionid.datatype    = "range(0,65535)"

mtu = s3:option(Value, "mtu", translate("MTU"))
mtu.placeholder = "1400"
mtu.datatype    = "range(512,1400)"

local connectValue = {"Keep connection","Automatic Connect/Disconnect","Manual Connect/Disconnect"}
connectionType = s3:option(ListValue, "connectionType", translate("Connection Type"))
        for i=1,#connectValue do connectionType:value(i-1,connectValue[i] ) end

connect = s3:option(Button, "connect", translate("connect"))
connect:depends("connectionType","2")

unconnect = s3:option(Button, "unconnect", translate("unconnect"))
unconnect:depends("connectionType","2")

dns = s3:option(Flag, "dns", translate("DNS Proxy Filter"))
dns.datatype = "bool"

idletime = s3:option(Value, "demand", translate("Idle Time"))
idletime.placeholder = "6000"
idletime.datatype    = "range(60,60000)"


dns:depends("connectionType","1")
idletime:depends("connectionType","1")

connectionType.write = function(self, section, value)
	if value ==  "0" then
		uci:set('network', 'wan', 'auto',1)
		uci:set('network', 'wan', 'demand',0)
	elseif value ==  "1" then
		uci:set('network', 'wan', 'auto',1)
	else
		uci:set('network', 'wan', 'demand',0)
	end
	uci:save('network')
	uci:commit('network')
end
