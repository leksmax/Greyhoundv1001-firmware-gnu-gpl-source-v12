--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: dhcp.lua 9623 2013-01-18 14:08:37Z jow $
]]--

local sys = require "luci.sys"

m = Map("dhcp", translate("DHCP and DNS"),
	translate("Dnsmasq is a combined DHCP-Server and DNS-Forwarder for NAT firewalls"))

s = m:section(TypedSection, "dnsmasq", translate("<br>Server Settings<br><br>General Setup"))
s.anonymous = true
s.addremove = false
s:option(Flag,"domainneeded",translate("Domain required"),	
	translate("Don't forward DNS-Requests without DNS-Name"))
s:option(Flag,"authoritative",	translate("Authoritative"),
	translate("Don't forward DNS-Requests without DNS-Name"))
s:option(Value,"local",	translate("Local server"))
s:option(Value,"domain",	translate("Local domain"))
s:option(Flag,"logqueries",	translate("Log queries"),
	translate("Don't forward DNS-Requests without DNS-Name")).optional = true
df = s:option(DynamicList,"server",	translate("DNS forwardings"))
df.placeholder = "/example.org/10.1.2.3"
rp = s:option(Flag, "rebind_protection",translate("Rebind protection"),
	translate("Discard upstream RFC1918 responses"))
rp.rmempty = false
rl = s:option(Flag, "rebind_localhost",	translate("Allow localhost"),
	translate("Allow upstream responses in the 127.0.0.0/8 range, e.g. for RBL services"))
rl:depends("rebind_protection", "1")
rd = s:option(DynamicList, "rebind_domain",	translate("Domain whitelist"))
rd:depends("rebind_protection", "1")
rd.datatype = "host"
rd.placeholder = "/example.org/10.1.2.3"

file = m:section(TypedSection, "dnsmasq", translate("<br>Resolv and Hosts Files"))
file.anonymous = true
file.addremove = false
file:option(Flag, "readethers",	translate("Use /etc/ethers"),
	translate("/etc/ethers to configure the DHCP-Server"))
file:option(Value, "leasefile",	translate("Leasefile"),translate("file where given DHCP-leases will be stored"))
file:option(Flag, "readethers",	translate("Ignore resolve file"),
	translate("Don't forward DNS-Requests without DNS-Name")).optional = true
rf = file:option(Value, "resolvfile",	translate("Resolve file"),
	translate("local DNS file"))
rf:depends("noresolv", "")
rf.optional = true
file:option(Flag, "nohosts",	translate("Ignore Hosts files"),
	translate("Don't forward DNS-Requests without DNS-Name")).optional = true
hf = file:option(DynamicList, "addnhosts",translate("Additional Hosts files"))
hf:depends("nohosts", "")
--hf.optional = true
hf.placeholder = "/example.org/10.1.2.3"

tftp = m:section(TypedSection, "dnsmasq", translate("<br>Tftp Settings"))
tftp.anonymous = true
tftp.addremove = false
tftp:option(Flag, "enable_tftp",
	translate("Enable TFTP server")).optional = true

advanced = m:section(TypedSection, "dnsmasq", translate("<br>Server Settings<br><br>Advanced Settings"))
advanced.anonymous = true
advanced.addremove = false
advanced:option(Flag, "boguspriv",	translate("Filter private"),
	translate("Do not forward reverse lookups for local networks"))
advanced:option(Flag, "filterwin2k",	translate("Filter useless"),
	translate("Do not forward requests that cannot be answered by public name servers"))
advanced:option(Flag, "localise_queries",	translate("Localise queries"),
	translate("Localise hostname depending on the requesting subnet if multiple IPs are available"))
advanced:option(Flag, "expandhosts",	translate("Expand hosts"),
	translate("Add local domain suffix to names served from hosts files"))
advanced:option(Flag, "nonegcache",		translate("No negative cache"),
	translate("Do not cache negative replies, e.g. for not existing domains"))
advanced:option(Flag, "strictorder",translate("Strict order"),
	translate("DNS servers will be queried in the order of the resolvfile")).optional = true	
bn = advanced:option(DynamicList, "bogusnxdomain", translate("Bogus NX Domain Override"),
	translate("List of hosts that supply bogus NX domain results"))
--bn.optional = true
bn.placeholder = "67.215.65.88"
pt = advanced:option(Value, "port",translate("DNS server port"),
	translate("Listening port for inbound DNS queries"))
--pt.optional = true
pt.datatype = "port"
pt.placeholder = "67.215.65.88"
lm = advanced:option(Value, "dhcpleasemax",	translate("Max.DHCP leases"),
	translate("Fix source port for outbound DNS queries"))
--lm.optional = true
lm.datatype = "uinteger"
lm.placeholder = "67.215.65.88"
em = advanced:option(Value, "ednspacket_max",translate("Max.EDNS0 packet size"),
	translate("Maximum allowed number of active DHCP leases"))
--em.optional = true
em.datatype = "uinteger"
em.placeholder = "67.215.65.88"
cq = advanced:option(Value, "dnsforwardmax",translate("Max.concurrent queries"),
	translate("Maximum allowed number of concurrent DNS queries"))
--cq.optional = true
cq.datatype = "uinteger"
cq.placeholder = "67.215.65.88"

return m
