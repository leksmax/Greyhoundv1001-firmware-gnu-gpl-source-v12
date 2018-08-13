--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local s2,s3,s4,s5,net = ...

local ipaddr, peeraddr, ip6addr, tunnelid, username, password
local defaultroute, metric, ttl, mtu


ipaddr = s2:option(Value, "ipaddr",
	translate("Local IPv4 address"),
	translate("Leave empty to use the current WAN address"))

ipaddr.datatype = "ip4addr"


peeraddr = s2:option(Value, "peeraddr",
	translate("Remote IPv4 address"),
	translate("This is usually the address of the nearest PoP operated by the tunnel broker"))

peeraddr.rmempty  = false
peeraddr.datatype = "ip4addr"


ip6addr = s2:option(Value, "ip6addr",
	translate("Local IPv6 address"),
	translate("This is the local endpoint address assigned by the tunnel broker, it usually ends with <code>:2</code>"))

ip6addr.rmempty  = false
ip6addr.datatype = "ip6addr"


local ip6prefix = s2:option(Value, "ip6prefix",
	translate("IPv6 routed prefix"),
	translate("This is the prefix routed to you by the tunnel broker for use by clients"))

ip6prefix.datatype = "ip6addr"


local update = s2:option(Flag, "_update",
	translate("Dynamic tunnel"),
	translate("Enable HE.net dynamic endpoint update"))

update.enabled  = "1"
update.disabled = "0"

function update.write() end
function update.remove() end
function update.cfgvalue(self, section)
	return (tonumber(m:get(section, "tunnelid")) ~= nil)
		and self.enabled or self.disabled
end


tunnelid = s2:option(Value, "tunnelid", translate("Tunnel ID"))
tunnelid.datatype = "uinteger"
tunnelid:depends("_update", update.enabled)


username = s2:option(Value, "username",
	translate("HE.net user ID"),
	translate("This is the 32 byte hex encoded user ID, not the login name"))

username:depends("_update", update.enabled)


password = s2:option(Value, "password", translate("HE.net password"))
password.password = true
password:depends("_update", update.enabled)


defaultroute = s3:option(Flag, "defaultroute",
	translate("Default gateway"),
	translate("If unchecked, no default route is configured"))

defaultroute.default = defaultroute.enabled


metric = s3:option(Value, "metric",
	translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"
metric:depends("defaultroute", defaultroute.enabled)


ttl = s3:option(Value, "ttl", translate("Use TTL on tunnel interface"))
ttl.placeholder = "64"
ttl.datatype    = "range(1,255)"


mtu = s3:option(Value, "mtu", translate("Use MTU on tunnel interface"))
mtu.placeholder = "1280"
mtu.datatype    = "max(1500)"
