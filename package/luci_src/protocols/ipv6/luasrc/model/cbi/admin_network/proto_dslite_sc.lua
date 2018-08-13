--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>
Copyright 2013 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local m2,s2,net = ...

local peeraddr, ip6addr
local tunlink, defaultroute, metric, ttl, mtu




peeraddr = s2:option(Value, "peeraddr",
	translate("DS-Lite AFTR address"))

peeraddr.rmempty  = false
peeraddr.datatype = "ip6addr"

ip6addr = s2:option(Value, "ip6addr",
	translate("Local IPv6 address"),
	translate("Leave empty to use the current WAN address"))