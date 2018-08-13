--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--
	
local m2,s2,net = ...

local s3, ipaddr, netmask, gateway, broadcast, dns, dns2, accept_ra, send_rs, ip6addr, ip6gw
local mtu, metric
local ipv6dns = {}
local ifc = net:get_interface()

if luci.model.network:has_ipv6() then

	local ip6assign = s2:option(Value, "ip6assign", translate("IPv6 assignment length"),
		translate("Assign a part of given length of every public IPv6-prefix to this interface"))
	ip6assign:value("", translate("disabled"))
	ip6assign:value("64")
	ip6assign.datatype = "max(64)"

	local ip6hint = s2:option(Value, "ip6hint", translate("IPv6 assignment hint"),
		translate("Assign prefix parts using this hexadecimal subprefix ID for this interface."))
	for i=33,64 do ip6hint:depends("ip6assign", i) end

	ip6addr = s2:option(Value, "ip6addr", translate("IPv6 address"))
	ip6addr.datatype = "ip6addr"
	ip6addr:depends("ip6assign", "")


	ip6gw = s2:option(Value, "ip6gw", translate("IPv6 gateway"))
	ip6gw.datatype = "ip6addr"
	ip6gw:depends("ip6assign", "")


	local ip6prefix = s2:option(Value, "ip6prefix", translate("IPv6 routed prefix"),
		translate("Public prefix routed to this device for distribution to clients."))
	ip6prefix.datatype = "ip6addr"
	ip6prefix:depends("ip6assign", "")
end
--[[
s3 = m2:section(NamedSection, "wan6" , "interface", translate("<br>Advanced Settings"))

auto = s3:option(Flag, "auto", translate("Bring up on boot"))
luci.tools.proto.opt_macaddr_sc(s3, ifc, translate("Override MAC address"))


mtu = s3:option(Value, "mtu", translate("Override MTU"))
mtu.placeholder = "1500"
mtu.datatype    = "max(1500)"

metric = s3:option( Value, "metric",
	translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"
]]
