--[[
LuCI - Lua Configuration Interface

Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local sys = require "luci.sys"
local fs  = require "nixio.fs"
local pt = require "luci.tools.proto"
local nw = require "luci.model.network"
local fw = require "luci.model.firewall"
local uci  = require "luci.model.uci".cursor()

m = SimpleForm("wol", translate("Wake on LAN"),
	translate("Wake on LAN is a mechanism to remotely boot computers in the local network."))

m.submit = translate("Wake up host / Submit")
m.reset  = false

nw.init(m.uci)
fw.init(m.uci)


local has_ewk = fs.access("/usr/bin/etherwake")
local has_wol = fs.access("/usr/bin/wol")


s = m:section(SimpleSection)
--[[
if has_ewk and has_wol then
	bin = s:option(ListValue, "binary", translate("WoL program"),
		translate("Sometimes only one of both tools work. If one of fails, try the other one"))

	bin:value("/usr/bin/etherwake", "Etherwake")
	bin:value("/usr/bin/wol", "WoL")
end

if has_ewk then
	iface = s:option(ListValue, "iface", translate("Network interface to use"),
		translate("Specifies the interface the WoL packet is sent on"))

	if has_wol then
		iface:depends("binary", "/usr/bin/etherwake")
	end

	--iface:value("", translate("Broadcast on all interfaces"))

	for _, e in ipairs(sys.net.devices()) do
		if e ~= "lo" then iface:value(e) end
	end
end
]]

host = s:option(Value, "mac", translate("Host to wake up"),
	translate("Choose the host to wake up or enter a custom MAC address to use"))



wol_enable = s:option(ListValue, "wol_enable", translate("Enable Wol via Wan"))
wol_enable.widget = "radio"
wol_enable.orientation = "horizontal"
wol_enable:value("1",translate("Enable"))
wol_enable:value("0",translate("Disable"))
wol_enable.default = uci:get("etherwake","setup","wol_enable")

wol_port = s:option(Value, "wol_port", translate("Port number"))
wol_port.default = _wol_port
wol_port.datatype= "port"
wol_port:depends("wol_enable", "1")

sys.net.mac_hints(function(mac, name)
	host:value(mac, "%s (%s)" %{ mac, name })
end)


function wol_enable.cfgvalue(self, section)
	return tostring(uci:get("etherwake", "setup", "wol_enable"))
end

function wol_port.cfgvalue(self, section)
	return tostring(uci:get("etherwake", "setup", "wol_port"))
end


function wol_enable.write(self, s, val)
	local wol_enable = luci.http.formvalue("cbid.wol.1.wol_enable")
	local wol_port = luci.http.formvalue("cbid.wol.1.wol_port")
	local wol_name 
	uci:foreach("firewall","redirect",
			function(s)
				if s["name"] == "wol" then
					wol_name = s[".name"]					
				end	

		end)		
	if  wol_enable == "1" then
	--port forwarding
		if wol_name ~= nil then
			uci:set("firewall",wol_name,"src_dport",wol_port)
		else
			uci:section("firewall","redirect",nil,{name='wol', src ='wan', proto = 'udp', src_dport=wol_port, dest_ip='192.168.1.254', target='DNAT', dest='lan'})
		end
		uci:set("etherwake","setup", "wol_enable", "1")
		uci:set("etherwake","setup", "wol_port", wol_port)
		--util = "/etc/init.d/wakeup enable;/etc/init.d/wakeup start"
	else
		if wol_name ~= nil then
			uci:delete("firewall",wol_name)
		end	
		uci:set("etherwake", "setup", "wol_enable", "0")
		--util = "/etc/init.d/wakeup enable;/etc/init.d/wakeup stop"
	end	
	--luci.util.exec(util)
	uci:save("etherwake")
	uci:save("firewall")
	uci:commit("etherwake")
	uci:commit("firewall")
	uci:apply("firewall")
	uci:apply("etherwake")
end

function wol_port.write(self, s, val)
	local wol_enable = luci.http.formvalue("cbid.wol.1.wol_enable")
	local wol_port = luci.http.formvalue("cbid.wol.1.wol_port")
	local wol_name 
	uci:foreach("firewall","redirect",
			function(s)
				if s["name"] == "wol" then
					wol_name = s[".name"]					
				end	

		end)		
	if  wol_enable == "1" then
	--port forwarding
		if wol_name ~= nil then
			uci:set("firewall",wol_name,"src_dport",wol_port)
		else
			uci:section("firewall","redirect",nil,{name='wol', src ='wan', proto = 'udp', src_dport=wol_port, dest_ip='192.168.1.254', target='DNAT', dest='lan'})
		end
		uci:set("etherwake","setup", "wol_enable", "1")
		uci:set("etherwake","setup", "wol_port", wol_port)
		--util = "/etc/init.d/wakeup enable;/etc/init.d/wakeup start"
	else
		if wol_name ~= nil then
			uci:delete("firewall",wol_name)
		end	
		uci:set("etherwake", "setup", "wol_enable", "0")
		--util = "/etc/init.d/wakeup enable;/etc/init.d/wakeup stop"
	end	
	--luci.util.exec(util)
	uci:save("etherwake")
	uci:save("firewall")
	uci:commit("etherwake")
	uci:commit("firewall")
	uci:apply("firewall")
	uci:apply("etherwake")
end		


function host.write(self, s, val)
	local host = luci.http.formvalue("cbid.wol.1.mac")
	if host and #host > 0 and host:match("^[a-fA-F0-9:]+$") then
		local cmd
		--local util = luci.http.formvalue("cbid.wol.1.binary") or (
		--	has_ewk and "/usr/bin/etherwake" or "/usr/bin/wol"
		--)
		local util = "/usr/bin/etherwake"

		if util == "/usr/bin/etherwake" then
			--local iface = luci.http.formvalue("cbid.wol.1.iface")
			local iface = 'br-lan'
			cmd = "%s -D%s %q" %{
				util, (iface ~= "" and " -i %q" % iface or ""), host
			}
		else
			cmd = "%s -v %q" %{ util, host }
		end

		local msg = "<p><strong>%s</strong><br /><br /><code>%s<br /><br />" %{
			translate("Starting WoL utility:"), cmd
		}

		local p = io.popen(cmd .. " 2>&1")
		if p then
			while true do
				local l = p:read("*l")
				if l then
					if #l > 100 then l = l:sub(1, 100) .. "..." end
					msg = msg .. l .. "<br />"
				else
					break
				end
			end
			p:close()
		end

		msg = msg .. "</code></p>"

		m.message = msg
	end
	
end


return m
