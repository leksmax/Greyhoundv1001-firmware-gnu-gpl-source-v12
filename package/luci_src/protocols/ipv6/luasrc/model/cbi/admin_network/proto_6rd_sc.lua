--[[
LuCI - Lua Configuration Interface

Copyright 2011-2012 Jo-Philipp Wich <xm@subsignal.org>

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
	translate("This IPv4 address of the relay"))

peeraddr.rmempty  = false
peeraddr.datatype = "ip4addr"


ip6addr = s2:option(Value, "ip6prefix",
	translate("IPv6 prefix"),
	translate("The IPv6 prefix assigned to the provider, usually ends with <code>::</code>"))

ip6addr.rmempty  = false
ip6addr.datatype = "ip6addr"


ip6prefixlen = s2:option(Value, "ip6prefixlen",
	translate("IPv6 prefix length"),
	translate("The length of the IPv6 prefix in bits"))

ip6prefixlen.placeholder = "16"
ip6prefixlen.datatype    = "range(0,128)"


ip6prefixlen = s2:option(Value, "ip4prefixlen",
	translate("IPv4 prefix length"),
	translate("The length of the IPv4 prefix in bits, the remainder is used in the IPv6 addresses."))

ip6prefixlen.placeholder = "0"
ip6prefixlen.datatype    = "range(0,32)"



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
