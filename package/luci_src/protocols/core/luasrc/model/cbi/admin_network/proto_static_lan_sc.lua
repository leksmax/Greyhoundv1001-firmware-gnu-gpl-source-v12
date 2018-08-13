--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--
	
local m2,s2,net = ...
local ifc = net:get_interface()

local ipaddr, netmask, gateway, broadcast, dns, accept_ra, send_rs, ip6addr, ip6gw
local mtu, metric
local uci = luci.model.uci.cursor()
ipaddr = s2:option(Value, "ipaddr", translate("IPv4 address"),translate("( %s ~ %s )" % {uci:get("dhcp", "lan", "start")  , uci:get("dhcp", "lan", "limit")}))
ipaddr.datatype = "ip4addr"


netmask = s2:option(Value, "netmask",
	translate("IPv4 netmask"))

netmask.datatype = "ip4addr"
netmask:value("255.255.255.0")
netmask:value("255.255.0.0")
netmask:value("255.0.0.0")


gateway = s2:option(Value, "gateway", translate("IPv4 gateway"))
gateway.datatype = "ip4addr"


broadcast = s2:option(Value, "broadcast", translate("IPv4 broadcast"))
broadcast.datatype = "ip4addr"

--[[
dns = s2:option(DynamicList, "dns",
	translate("Use custom DNS servers"))

dns.datatype = "ipaddr"
dns.cast     = "string"
]]

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

