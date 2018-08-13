--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local m2,s2,net = ...

local s3, username, password, ac, service, connectionType, dns, mtu, idletime, connect, unconnect, auto, ipv6

local uci = luci.model.uci.cursor()

username = s2:option(Value, "username", translate("Username"))
username.datatype    = "hostname"

password = s2:option(Value, "password", translate("Password"))
password.datatype = "maxlength(64)"
password.password = true

service = s2:option(Value, "service",
	translate("Service"))

service.placeholder = translate("auto")
s3 = m2:section(NamedSection, "wan6" , "interface", translate("<br>Advanced Settings"))
auto = s3:option(Flag, "auto", translate("Bring up on boot"))
auto.default = (net:proto() == "none") and auto.disabled or auto.enabled
--[[
defaultroute = s3:option(Flag, "defaultroute",
       translate("Use default gateway"),
       translate("If unchecked, no default route is configured"))

defaultroute.default = defaultroute.enabled


metric = s3:option(Value, "metric",
       translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"
metric:depends("defaultroute", defaultroute.enabled)


peerdns = s3:option(Flag, "peerdns",
       translate("Use DNS servers advertised by peer"),
       translate("If unchecked, the advertised DNS server addresses are ignored"))

peerdns.default = peerdns.enabled

dns = s3:option(DynamicList, "dns",
       translate("Use custom DNS servers"))

dns:depends("peerdns", "")
dns.datatype = "ipaddr"
dns.cast     = "string"

keepalive_failure = s3:option(Value, "_keepalive_failure",
       translate("LCP echo failure threshold"),
       translate("Presume peer to be dead after given amount of LCP echo failures, use 0 to ignore failures"))

function keepalive_failure.cfgvalue(self, section)
	local v = m:get(section, "keepalive")
	if v and #v > 0 then
		return tonumber(v:match("^(%d+)[ ,]+%d+") or v)
	end
end

function keepalive_failure.write() end
function keepalive_failure.remove() end

keepalive_failure.placeholder = "0"
keepalive_failure.datatype    = "uinteger"


keepalive_interval = s3:option(Value, "_keepalive_interval",
       translate("LCP echo interval"),
       translate("Send LCP echo requests at the given interval in seconds, only effective in conjunction with failure threshold"))

function keepalive_interval.cfgvalue(self, section)
	local v = m:get(section, "keepalive")
	if v and #v > 0 then
		return tonumber(v:match("^%d+[ ,]+(%d+)"))
	end
end

function keepalive_interval.write(self, section, value)
	local f = tonumber(keepalive_failure:formvalue(section)) or 0
	local i = tonumber(value) or 5
	if i < 1 then i = 1 end
	if f > 0 then
		m:set(section, "keepalive", "%d %d" %{ f, i })
	else
		m:del(section, "keepalive")
	end
end

keepalive_interval.remove      = keepalive_interval.write
keepalive_interval.placeholder = "5"
keepalive_interval.datatype    = "min(1)"
]]

demand = s3:option(Value, "demand",
       translate("Inactivity timeout"),
       translate("Close inactive connection after the given amount of seconds, use 0 to persist connection"))

demand.placeholder = "0"
demand.datatype    = "uinteger"

 
mtu = s3:option(Value, "mtu", translate("Override MTU"))
mtu.placeholder = "1500"
mtu.datatype    = "max(1500)"


uci:set('network', 'wan6', 'ipv6',1)
uci:save('network')
uci:commit('network')