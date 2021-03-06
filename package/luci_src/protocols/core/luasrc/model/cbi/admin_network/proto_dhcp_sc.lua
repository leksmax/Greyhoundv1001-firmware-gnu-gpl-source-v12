--[[
LuCI - Lua Configuration Interface

Copyright 2011-2012 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local m2,s2,net = ...
local ifc = net:get_interface()

local hostname, accept_ra, send_rs
local bcast, defaultroute, peerdns, dns, metric, clientid, vendorclass


hostname = s2:option(Value, "hostname",
	translate("Hostname"))

hostname.placeholder = luci.sys.hostname()
hostname.datatype    = "hostname"
