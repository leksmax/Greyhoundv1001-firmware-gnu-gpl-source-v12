--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local m2,s2,net = ...

local username, password, ac, service, connectionType, dns,mtu,idletime,connect,unconnect

local uci = luci.model.uci.cursor()

username = s2:option(Value, "username", translate("Username"))
username.datatype    = "hostname"

password = s2:option(Value, "password", translate("Password"))
password.datatype = "maxlength(64)"
password.password = true

service = s2:option(Value, "service",
	translate("Service"))

service.placeholder = translate("auto")

mtu = s2:option(Value, "mtu", translate("MTU"))
mtu.placeholder = "1492"
mtu.datatype    = "range(512,1492)"

local connectValue = {"Keep connection","Automatic Connect/Disconnect","Manual Connect/Disconnect"}
connectionType = s2:option(ListValue, "connectionType", translate("Connection Type"))
        for i=1,#connectValue do connectionType:value(i-1,connectValue[i] ) end

connect = s2:option(Button, "connect", translate("connect"))
connect:depends("connectionType","2")

unconnect = s2:option(Button, "unconnect", translate("unconnect"))
unconnect:depends("connectionType","2")

dns = s2:option(Flag, "dns", translate("DNS Proxy Filter"))
dns.datatype = "bool"

idletime = s2:option(Value, "demand", translate("Idle Time"))
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


