--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--
	
local m2,s2,net = ...

local ipaddr, netmask, gateway, broadcast, dns, accept_ra, send_rs, ip6addr, ip6gw
local mtu, metric

local uci = luci.model.uci.cursor()
ipaddr = s2:option(Value, "ipaddr", translate("IP address"))
ipaddr.datatype = "ip4addr"


netmask = s2:option(Value, "netmask",
	translate("Subnet Mask"))

netmask.datatype = "ip4addr"
netmask:value("255.255.255.0")
netmask:value("255.255.0.0")
netmask:value("255.0.0.0")


gateway = s2:option(Value, "gateway", translate("Default Gateway"))
gateway.datatype = "ip4addr"
--[[
dns = s2:option(DynamicList, "dns",
	translate("DNS servers"))

dns.datatype = "ipaddr"
dns.cast     = "string"
]]