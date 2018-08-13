--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008-2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ifaces.lua 9067 2012-08-17 08:24:24Z jow $
]]--

local fs = require "nixio.fs"
require "luci.sys"
local ut = require "luci.util"
local pt = require "luci.tools.proto"
local nw = require "luci.model.network"
local fw = require "luci.model.firewall"

arg[1] = arg[1] or ""

local has_dnsmasq  = fs.access("/etc/config/dhcp")
local has_firewall = fs.access("/etc/config/firewall")

m = Map("network", translate("Interfaces") .. " - " .. arg[1]:upper(), translate("On this page you can configure the network interfaces. You can bridge several interfaces by ticking the \"bridge interfaces\" field and enter the names of several network interfaces separated by spaces. You can also use <abbr title=\"Virtual Local Area Network\">VLAN</abbr> notation <samp>INTERFACE.VLANNR</samp> (<abbr title=\"for example\">e.g.</abbr>: <samp>eth0.1</samp>)."))
m:chain("wireless")

if has_firewall then
	m:chain("firewall")
end

nw.init(m.uci)
fw.init(m.uci)


local net = nw:get_network(arg[1])

local function backup_ifnames(is_bridge)
	if not net:is_floating() and not m:get(net:name(), "_orig_ifname") then
		local ifcs = net:get_interfaces() or { net:get_interface() }
		if ifcs then
			local _, ifn
			local ifns = { }
			for _, ifn in ipairs(ifcs) do
				ifns[#ifns+1] = ifn:name()
			end
			if #ifns > 0 then
				m:set(net:name(), "_orig_ifname", table.concat(ifns, " "))
				m:set(net:name(), "_orig_bridge", tostring(net:is_bridge()))
			end
		end
	end
end


-- redirect to overview page if network does not exist anymore (e.g. after a revert)
if not net then
	luci.http.redirect(luci.dispatcher.build_url("admin/interfaces/overview"))
	return
end

-- protocol switch was requested, rebuild interface config and reload page
if m:formvalue("cbid.network.%s._switch" % net:name()) then
	-- get new protocol
	local ptype = m:formvalue("cbid.network.%s.proto" % net:name()) or "-"
	local proto = nw:get_protocol(ptype, net:name())
	if proto then
		-- backup default
		backup_ifnames()

		-- if current proto is not floating and target proto is not floating,
		-- then attempt to retain the ifnames
		--error(net:proto() .. " > " .. proto:proto())
		if not net:is_floating() and not proto:is_floating() then
			-- if old proto is a bridge and new proto not, then clip the
			-- interface list to the first ifname only
			if net:is_bridge() and proto:is_virtual() then
				local _, ifn
				local first = true
				for _, ifn in ipairs(net:get_interfaces() or { net:get_interface() }) do
					if first then
						first = false
					else
						net:del_interface(ifn)
					end
				end
				m:del(net:name(), "type")
			end

		-- if the current proto is floating, the target proto not floating,
		-- then attempt to restore ifnames from backup
		elseif net:is_floating() and not proto:is_floating() then
			-- if we have backup data, then re-add all orphaned interfaces
			-- from it and restore the bridge choice
			local br = (m:get(net:name(), "_orig_bridge") == "true")
			local ifn
			local ifns = { }
			for ifn in ut.imatch(m:get(net:name(), "_orig_ifname")) do
				ifn = nw:get_interface(ifn)
				if ifn and not ifn:get_network() then
					proto:add_interface(ifn)
					if not br then
						break
					end
				end
			end
			if br then
				m:set(net:name(), "type", "bridge")
			end

		-- in all other cases clear the ifnames
		else
			local _, ifc
			for _, ifc in ipairs(net:get_interfaces() or { net:get_interface() }) do
				net:del_interface(ifc)
			end
			m:del(net:name(), "type")
		end

		-- clear options
		local k, v
		for k, v in pairs(m:get(net:name())) do
			if k:sub(1,1) ~= "." and
			   k ~= "type" and
			   k ~= "ifname" and
			   k ~= "_orig_ifname" and
			   k ~= "_orig_bridge"
			then
				m:del(net:name(), k)
			end
		end

		-- set proto
		m:set(net:name(), "proto", proto:proto())
		m.uci:save("network")
		m.uci:save("wireless")

		-- reload page
		luci.http.redirect(luci.dispatcher.build_url("admin/interfaces/overview", arg[1]))
		return
	end
end

-- dhcp setup was requested, create section and reload page
if m:formvalue("cbid.dhcp._enable._enable") then
	m.uci:section("dhcp", "dhcp", nil, {
		interface = arg[1],
		start     = "100",
		limit     = "150",
		leasetime = "12h"
	})

	m.uci:save("dhcp")
	luci.http.redirect(luci.dispatcher.build_url("admin/interfaces/overview", arg[1]))
	return
end

local ifc = net:get_interface()

-- s = m:section(NamedSection, arg[1], "interface", translate("Common Configuration"))
-- s.addremove = false

--General Setup
m2 = Map("network", "", "")
s2 = m2:section(NamedSection, arg[1], "interface", translate("Common Configuration<br><br>General Setup"))
s2.addremove = false
st = s2:option(DummyValue, "status", translate("Status"))

local function set_status()
	-- if current network is empty, print a warning
	if not net:is_floating() and net:is_empty() then
		st.template = "cbi/dvalue"
		st.network  = nil
		st.value    = translate("There is no device assigned yet, please attach a network device in the \"Physical Settings\" tab")
	else
		st.template = "admin_network/iface_status"
		st.network  = arg[1]
		st.value    = nil
	end
end

m2.on_init = set_status
m2.on_after_save = set_status

if arg[1] == "lan" then --lan
local sa
sa = s2:option(DummyValue, "protocol", translate("Protocol"))
scdns = s2:option(DummyValue, "")
form, ferr = loadfile(
	ut.libpath() .. "/model/cbi/admin_network/proto_%s_lan_sc.lua" % net:proto()
)
	scdns.network = "lan"		
	scdns.template = "admin_network/iface_dns_sc"

elseif  arg[1] == "wan" then--wan
p = s2:option(ListValue, "proto", translate("Protocol"))
sc = s2:option(DummyValue, "")
scdns = s2:option(DummyValue, "")

p.default = net:proto()

if not net:is_installed() then
	p_install = s2:option(Button, "_install")
	p_install.title      = translate("Protocol support is not installed")
	p_install.inputtitle = translate("Install package %q" % net:opkg_package())
	p_install.inputstyle = "apply"
	p_install:depends("proto", net:proto())

	function p_install.write()
		return luci.http.redirect(
			luci.dispatcher.build_url("admin/system/packages") ..
			"?submit=1&install=%s" % net:opkg_package()
		)
	end
end


local _, pr

for _, pr in ipairs(nw:get_protocols()) do
	if pr:proto()=="static" or pr:proto()=="dhcp" or pr:proto()=="pppoe" or pr:proto()=="pptp" or pr:proto()=="l2tp" or pr:proto()=="dslite" then 
		p:value(pr:proto(), pr:get_i18n())
		sc.template = "admin_network/iface_sc"
		sc.network = "wan"
		if  luci.http.formvalue("cbid.network.wan.proto") ~= nil then
		form, ferr = loadfile(
			ut.libpath() .. "/model/cbi/admin_network/proto_%s_sc.lua" % luci.http.formvalue("cbid.network.wan.proto")
		)
		else
		form, ferr = loadfile(
			ut.libpath() .. "/model/cbi/admin_network/proto_%s_sc.lua" % net:proto()
		)			
		end
		if pr:proto()=="static" then
			scdns.network = "wan"		
			scdns.template = "admin_network/iface_dns_sc"
		end	
	end
end
else
p = s2:option(ListValue, "proto", translate("Protocol"))
sc = s2:option(DummyValue, "")
p.default = net:proto()

if not net:is_installed() then
	p_install = s2:option(Button, "_install")
	p_install.title      = translate("Protocol support is not installed")
	p_install.inputtitle = translate("Install package %q" % net:opkg_package())
	p_install.inputstyle = "apply"
	p_install:depends("proto", net:proto())

	function p_install.write()
		return luci.http.redirect(
			luci.dispatcher.build_url("admin/system/packages") ..
			"?submit=1&install=%s" % net:opkg_package()
		)
	end
end

		p:value("static","Static Ipv6")
		p:value("pppoe","PPPoE")
		p:value("dhcpv6","Autoconfiguration")
		p:value("6rd","6RD")
		p:value("linklocal","Link-local only")		
		sc.template = "admin_network/iface_sc"
		sc.network = "wan6"
		if  luci.http.formvalue("cbid.network.wan6.proto") ~= nil then
		form, ferr = loadfile(
			ut.libpath() .. "/model/cbi/admin_network/proto_%s_wan6_sc.lua" % luci.http.formvalue("cbid.network.wan6.proto")
		)
		else
		form, ferr = loadfile(
			ut.libpath() .. "/model/cbi/admin_network/proto_%s_wan6_sc.lua" % net:proto()
		)
		end
		if luci.http.formvalue("cbid.network.wan6.proto") == "static" or net:proto() == "static"  then
			scdns = s2:option(DummyValue, "")
			scdns.network = "wan6"		
			scdns.template = "admin_network/iface_dns_sc"
		end	
end

--Physical Settings
if arg[1] == "lan" then
m4 = Map("network", "", "")
s4 = m4:section(NamedSection, arg[1] , "interface", translate("Physical Settings"))

if not net:is_virtual() then
	stp = s4:option(Flag, "stp", translate("Enable <abbr title=\"Spanning Tree Protocol\">STP</abbr>"),
		translate("Enables the Spanning Tree Protocol on this bridge"))
	stp.rmempty = true
end
--[[
elseif arg[1] == "wan6" then
--Physical Settings
--m4 = Map("network", "", "")
if( luci.http.formvalue("cbid.network.wan6.proto") ~= "6rd" and net:proto() ~= "6rd"  
	and luci.http.formvalue("cbid.network.wan6.proto") ~= "linklocal" and net:proto() ~= "linklocal" )then
s4 = m2:section(NamedSection, arg[1] , "interface", translate("<br>Physical Settings"))

if not net:is_virtual() then
	br = s4:option(Flag, "type", translate("Bridge interfaces"), translate("creates a bridge over specified interface(s)"))
	br.enabled = "bridge"
	br.rmempty = true
	br:depends("proto", "static")
	br:depends("proto", "dhcp")
	br:depends("proto", "none")

	stp = s4:option(Flag, "stp", translate("Enable <abbr title=\"Spanning Tree Protocol\">STP</abbr>"),
		translate("Enables the Spanning Tree Protocol on this bridge"))
	stp:depends("type", "bridge")
	stp.rmempty = true

end

if not net:is_floating() then
	ifname_single = s4:option(Value, "ifname_single", translate("Interface"))
	ifname_single.template = "cbi/network_ifacelist_sc"
	ifname_single.widget = "radio"
	ifname_single.nobridges = true
	ifname_single.rmempty = false
	ifname_single.network = arg[1]
	ifname_single:depends("type", "")

	function ifname_single.cfgvalue(self, s)
		-- let the template figure out the related ifaces through the network model
		return nil
	end

	function ifname_single.write(self, s, val)
		local i
		local new_ifs = { }
		local old_ifs = { }

		for _, i in ipairs(net:get_interfaces() or { net:get_interface() }) do
			old_ifs[#old_ifs+1] = i:name()
		end

		for i in ut.imatch(val) do
			new_ifs[#new_ifs+1] = i

			-- if this is not a bridge, only assign first interface
			if self.option == "ifname_single" then
				break
			end
		end

		table.sort(old_ifs)
		table.sort(new_ifs)

		for i = 1, math.max(#old_ifs, #new_ifs) do
			if old_ifs[i] ~= new_ifs[i] then
				backup_ifnames()
				for i = 1, #old_ifs do
					net:del_interface(old_ifs[i])
				end
				for i = 1, #new_ifs do
					net:add_interface(new_ifs[i])
				end
				break
			end
		end
	end
end

if not net:is_virtual() then
	ifname_multi = s4:option(Value, "ifname_multi", translate("Interface"))
	ifname_multi.template = "cbi/network_ifacelist_sc"
	ifname_multi.nobridges = true
	ifname_multi.rmempty = false
	ifname_multi.network = arg[1]
	ifname_multi.widget = "checkbox"
	ifname_multi:depends("type", "bridge")
	ifname_multi.cfgvalue = ifname_single.cfgvalue
	ifname_multi.write = ifname_single.write
end

end
]]
end
--[[
if arg[1] == "wan6" and luci.http.formvalue("cbid.network.wan6.proto") ~= "linklocal" and net:proto() ~= "linklocal" then
	m5 = Map("network", "", "")
	s5 = m2:section(NamedSection, arg[1] , "interface", translate("<br>Firewall Settings"))	

	if has_firewall then
		fwzone = s5:option(Value, "_fwzone",
			translate("Create / Assign firewall-zone"),
			translate("Choose the firewall zone you want to assign to this interface. Select <em>unspecified</em> to remove the interface from the associated zone or fill out the <em>create</em> field to define a new zone and attach the interface to it."))

		fwzone.template = "cbi/firewall_zonelist_sc"
		fwzone.network = arg[1]
		fwzone.rmempty = false

		function fwzone.cfgvalue(self, section)
			self.iface = section
			local z = fw:get_zone_by_network(section)
			return z and z:name()
		end

		function fwzone.write(self, section, value)
			local zone = fw:get_zone(value)

			if not zone and value == '-' then
				value = m:formvalue(self:cbid(section) .. ".newzone")
				if value and #value > 0 then
					zone = fw:add_zone(value)
				else
					fw:del_network(section)
				end
			end

			if zone then
				fw:del_network(section)
				zone:add_network(section)
			end
		end
	end
end
]]


if not form then
	s2:option(DummyValue, "_error",
		translate("Missing protocol extension for proto %q" % net:proto())
	).value = ferr
else
	setfenv(form, getfenv(1))(m2,s2,net )
end

if arg[1] == "lan" then
m6 = Map("dhcp", "", "")

	local has_section = false

	m6.uci:foreach("dhcp", "dhcp", function(s)
		if s.interface == arg[1] then
			has_section = true
			return false
		end
	end)

	if not has_section then

		s6 = m6:section(TypedSection, "dhcp", translate("DHCP Server"))
		s6.anonymous   = true
		s6.cfgsections = function() return { "_enable" } end
		x = s6:option(Button, "_enable")
		x.title      = translate("No DHCP Server configured for this interface")
		x.inputtitle = translate("Setup DHCP Server")
		x.inputstyle = "apply"

	else

		s6 = m6:section(TypedSection, "dhcp", translate("DHCP Server"))
		s6.addremove = false
		s6.anonymous = true

		--gs = s6:option(DummyValue,"gs",translate("General Setup"))
		function s6.filter(self, section)
			return m6.uci:get("dhcp", section, "interface") == arg[1]
		end

		local ignore = s6:option(Flag, "ignore",
		translate("Ignore interface"),
		translate("Disable DHCP for this interface."))

		local start = s6:option(Value, "start", translate("Start"),
			translate("Lowest leased address as offset from the network address."))
		start.optional = true
		start.datatype = "or(uinteger,ip4addr)"
		start.default = "100"

		local limit = s6:option(Value, "limit", translate("Limit"),
			translate("Maximum number of leased addresses."))
		limit.optional = true
		limit.datatype = "uinteger"
		limit.default = "150"

		local ltime = s6:option(Value, "leasetime", translate("Leasetime"),
			translate("Expiry time of leased addresses, minimum is 2 Minutes (<code>2m</code>)."))
		ltime.rmempty = true
		ltime.default = "12h"

		for i, n in ipairs(s6.children) do
			if n ~= ignore then
				n:depends("ignore", "")
			end
		end
	end
	local slan
	m7 = Map("dhcp6s", "", "")
	s7 = m7:section(NamedSection, "basic","dhcp6s", translate("IPv6"))
	s7.addremove = false
	slan = s7:option(DummyValue, "")
	slan.template = "admin_network/iface_sc"
	slan.network = "lan"
	local uci = luci.model.uci.cursor()
	if nixio.fs.access("/etc/config/dhcp6s") then
		local dhcp6s_basic = luci.http.formvalue("dhcp6s_basic")
		if dhcp6s_basic ~= nil then
			uci:set('dhcp6s', 'basic', 'enabled',1)
		else
			uci:set('dhcp6s', 'basic', 'enabled',0)
		end
		local IPstart = luci.http.formvalue("IPstart")
		if IPstart ~= nil then
			uci:set('dhcp6s', 'basic', 'IPstart',IPstart)
		else
			uci:set('dhcp6s', 'basic', 'IPstart',1)
		end
		local IPend = luci.http.formvalue("IPend")
		if IPend ~= nil then
			uci:set('dhcp6s', 'basic', 'IPend',IPend)
		else
			uci:set('dhcp6s', 'basic', 'IPend',100)
		end
		uci:save("dhcp6s")
		uci:commit("dhcp6s")
	end
	if nixio.fs.access("/etc/config/radvd") then
		local autoConfig = luci.http.formvalue("autoConfig")
		local lifetime = luci.http.formvalue("lifetime")
		if autoConfig ==  "0" then
			uci:foreach("radvd", "interface", function(s)
			uci:set("radvd", s[".name"], "AdvManagedFlag", 0)end)
			uci:foreach("radvd", "interface", function(s)
			uci:set("radvd", s[".name"], "AdvOtherConfigFlag", 0)end)
		elseif autoConfig ==  "1" then
			uci:foreach("radvd", "interface", function(s)
			uci:set("radvd", s[".name"], "AdvManagedFlag", 0)end)
			uci:foreach("radvd", "interface", function(s)
			uci:set("radvd", s[".name"], "AdvOtherConfigFlag", 1)end)
		else
			uci:foreach("radvd", "interface", function(s)
			uci:set("radvd", s[".name"], "AdvManagedFlag", 1)end)
			uci:foreach("radvd", "interface", function(s)
			uci:set("radvd", s[".name"], "AdvOtherConfigFlag", 0)end)
		end
		if lifetime ~= nil then
			uci:foreach("radvd", "prefix", function(s)
			uci:set("radvd", s[".name"], "AdvValidLifetime", lifetime)end)
		else
			uci:foreach("radvd", "prefix", function(s)
			uci:set("radvd", s[".name"], "AdvValidLifetime", 0)end)
		end

		uci:save('radvd')
		uci:commit('radvd')
	end
end
	local uci = luci.model.uci.cursor()
	function input(v)
		return luci.http.formvalue(v) or ""
	end
			-- DNS
			local str_dns
			if input("ipv4dns1") == "" then
				str_dns = "0.0.0.0"
			else
				str_dns = input("ipv4dns1")
			end
			
			if input("ipv4dns2") == "" then
				str_dns = str_dns .. " 0.0.0.0"
			else
				str_dns = str_dns .. " " .. input("ipv4dns2")
			end
	
			if input("ipv6dns1") ~="" then
				str_dns = string.format("%s %s", str_dns, input("ipv6dns1"))
			end
			if input("ipv6dns2") ~="" then
				str_dns = string.format("%s %s", str_dns, input("ipv6dns2"))
			end
		uci:set("network", "lan", "dns", str_dns)
		uci:save("network")
		uci:commit("network")
return m, m2 ,m4, m6, m7