--[[
LuCI - Lua Configuration Interface

Copyright 2013 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local m2,s2,net = ...
local auto
local ifc = net:get_interface()

local o = s2:option(ListValue, "reqaddress",
	translate("Request IPv6-address"))
o:value("try")
o:value("force")
o:value("none", "disabled")
o.default = "try"


o = s2:option(Value, "reqprefix",
	translate("Request IPv6-prefix of length"))
o:value("auto", translate("automatic"))
o:value("no", translate("disabled"))
o:value("48")
o:value("52")
o:value("56")
o:value("60")
o:value("64")
o.default = "auto"
--[[
s3 = m2:section(NamedSection, "wan6" , "interface", translate("<br>Advanced Settings"))

auto = s3:option(Flag, "auto", translate("Bring up on boot"))
auto.default = (net:proto() == "none") and auto.disabled or auto.enabled

o = s3:option(Flag, "defaultroute",
	translate("Use default gateway"),
	translate("If unchecked, no default route is configured"))
o.default = o.enabled


o = s3:option(Flag, "peerdns",
	translate("Use DNS servers advertised by peer"),
	translate("If unchecked, the advertised DNS server addresses are ignored"))
o.default = o.enabled


o = s3:option( Value, "ip6prefix",
	translate("Custom delegated IPv6-prefix"))
o.dataype = "ip6addr"


o = s3:option(DynamicList, "dns",
	translate("Use custom DNS servers"))
o:depends("peerdns", "")
o.datatype = "list(ip6addr)"
o.cast     = "string"


o = s3:option(Value, "clientid",
	translate("Client ID to send when requesting DHCP"))

luci.tools.proto.opt_macaddr_sc(s3, ifc, translate("Override MAC address"))

o = s3:option(Value, "mtu", translate("Override MTU"))
o.placeholder = "1500"
o.datatype    = "max(1500)"
]]