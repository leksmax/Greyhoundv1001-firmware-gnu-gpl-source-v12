--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: wifi.lua 9558 2012-12-18 13:58:22Z jow $
]]--

local wa = require "luci.tools.webadmin"
local nw = require "luci.model.network"
local ut = require "luci.util"
local nt = require "luci.sys".net
local fs = require "nixio.fs"

arg[1] = arg[1] or ""

m = Map("wireless", "",
	translate("The <em>Device Configuration</em> section covers physical settings of the radio " ..
		"hardware such as channel, transmit power or antenna selection which is shared among all " ..
		"defined wireless networks (if the radio hardware is multi-SSID capable). Per network settings " ..
		"like encryption or operation mode are grouped in the <em>Interface Configuration</em>."))

m:chain("network")
m:chain("firewall")

local ifsection

function m.on_commit(map)
	local wnet = nw:get_wifinet(arg[1])
	if ifsection and wnet then
		ifsection.section = wnet.sid
		m.title = luci.util.pcdata(wnet:get_i18n())
	end
end

nw.init(m.uci)

local wnet = nw:get_wifinet(arg[1])
local wdev = wnet and wnet:get_device()

-- redirect to overview page if network does not exist anymore (e.g. after a revert)
if not wnet or not wdev then
	luci.http.redirect(luci.dispatcher.build_url("admin/wifi/overview"))
	return
end

-- wireless toggle was requested, commit and reload page
function m.parse(map)
	if m:formvalue("cbid.wireless.%s.__toggle" % wdev:name()) then
		if wdev:get("disabled") == "1" or wnet:get("disabled") == "1" then
			wnet:set("disabled", nil)
		else
			wnet:set("disabled", "1")
		end
		wdev:set("disabled", nil)

		nw:commit("wireless")
		luci.sys.call("(env -i /sbin/wifi down; env -i /sbin/wifi up) >/dev/null 2>/dev/null")

		luci.http.redirect(luci.dispatcher.build_url("admin/wifi/overview", arg[1]))
		return
	end
	Map.parse(map)
end

m.title = luci.util.pcdata(wnet:get_i18n())


local function txpower_list(iw)
	local list = iw.txpwrlist or { }
	local off  = tonumber(iw.txpower_offset) or 0
	local new  = { }
	local prev = -1
	local _, val
	for _, val in ipairs(list) do
		local dbm = val.dbm + off
		local mw  = math.floor(10 ^ (dbm / 10))
		if mw ~= prev then
			prev = mw
			new[#new+1] = {
				display_dbm = dbm,
				display_mw  = mw,
				driver_dbm  = val.dbm,
				driver_mw   = val.mw
			}
		end
	end
	return new
end

local function txpower_current(pwr, list)
	pwr = tonumber(pwr)
	if pwr ~= nil then
		local _, item
		for _, item in ipairs(list) do
			if item.driver_dbm >= pwr then
				return item.driver_dbm
			end
		end
	end
	return (list[#list] and list[#list].driver_dbm) or pwr or 0
end

local iw = luci.sys.wifi.getiwinfo(arg[1])
local hw_modes      = iw.hwmodelist or { }

local tx_power_list = txpower_list(iw)
local tx_power_cur  = txpower_current(wdev:get("txpower"), tx_power_list)

s = m:section(NamedSection, wdev:name(), "wifi-device", translate("Device Configuration<br><br>General Setup "))
s.addremove = false


-- s:tab("general", translate("General Setup"))
-- s:tab("macfilter", translate("MAC-Filter"))
-- s:tab("advanced", translate("Advanced Settings"))

--[[
back = s:option(DummyValue, "_overview", translate("Overview"))
back.value = ""
back.titleref = luci.dispatcher.build_url("admin", "network", "wireless")
]]

st = s:option(DummyValue, "__status", translate("Status"))
st.template = "admin_network/wifi_status"
st.ifname   = arg[1]

en = s:option(Button, "__toggle")

if wdev:get("disabled") == "1" or wnet:get("disabled") == "1" then
	en.title      = translate("Wireless network is disabled")
	en.inputtitle = translate("Enable")
	en.inputstyle = "apply"
else
	en.title      = translate("Wireless network is enabled")
	en.inputtitle = translate("Disable")
	en.inputstyle = "reset"
end


local hwtype = wdev:get("type")
local htcaps = wdev:get("ht_capab") and true or false

-- NanoFoo
local nsantenna = wdev:get("antenna")

-- Check whether there is a client interface on the same radio,
-- if yes, lock the channel choice as the station will dicatate the freq
-- local has_sta = nil
-- local _, net
-- for _, net in ipairs(wdev:get_wifinets()) do
-- 	if net:mode() == "sta" and net:id() ~= wnet:id() then
-- 		has_sta = net
-- 		break
-- 	end
-- end

-- if has_sta then
-- 	ch = s:option(DummyValue, "choice", translate("Channel"))
-- 	ch.value = translatef("Locked to channel %d used by %s",
-- 		has_sta:channel(), has_sta:shortname())
-- else
-- 	ch = s:option(Value, "channel", translate("Channel"))
-- 	ch:value("auto", translate("auto"))
-- 	for _, f in ipairs(iw and iw.freqlist or { }) do
-- 		if not f.restricted then
-- 			ch:value(f.channel, "%i (%.3f GHz)" %{ f.channel, f.mhz / 1000 })
-- 		end
-- 	end
-- end

-- channel = s:option(ListValue, "channel", translate("Channel"))
-- 	--channel option--		
-- 	--setSelectOption("wifi_file","channel",channel)
-- 	local wifi_ifname = luci.util.exec("iwconfig 2>/dev/null |grep -E '^ath([0]|[0|2][0-9]) '|head -n 1|awk {'printf $1'}")
-- 	os.execute("iwlist %s channel | grep Channel | sed -n 's/Channel/Ch/gp' > /tmp/ui_channel_info" % wifi_ifname)
-- 	os.execute("cat /tmp/ui_channel_info | awk '{print $2}' | sed 's/^0//' > /tmp/ui_ch_val")
-- 	local ch_info = {}
-- 	local ch_val = {}
-- 	local file = io.open("/tmp/ui_channel_info","r")
-- 	local file2 = io.open("/tmp/ui_ch_val","r")
-- 	for line in file:lines() do
-- 		table.insert(ch_info,line)
-- 	end
-- 	for line2 in file2:lines() do
-- 		table.insert(ch_val,line2)
-- 	end
-- 	channel:value("auto","Auto")
-- 	for k,v in pairs(ch_info) do
-- 		channel:value(ch_val[k],v)
-- 	end
-- 	file:close()
-- 	file2:close()
-- 	os.execute("rm -rf /tmp/ui_channel_info")
-- 	os.execute("rm -rf /tmp/ui_ch_val")
-- 	-- channel.default = m.uci:get("wireless","wifi0","channel")	

local has_sta = nil
local _, net
for _, net in ipairs(wdev:get_wifinets()) do
	if net:mode() == "sta" and net:id() ~= wnet:id() then
		has_sta = net
		break
	end
end

if has_sta then
	ch = s:option(DummyValue, "choice", translate("Channel"))
	ch.value = translatef("Locked to channel %d used by %s",
		has_sta:channel(), has_sta:shortname())
else
	ch = s:option(Value, "channel", translate("Channel"))
	ch:value("auto", translate("auto"))
	for _, f in ipairs(iw and iw.freqlist or { }) do
		if not f.restricted then
			ch:value(f.channel, "%i (%.3f GHz)" %{ f.channel, f.mhz / 1000 })
		end
	end
end


------------------- MAC80211 Device ------------------

if hwtype == "mac80211" then
	if #tx_power_list > 1 then
		tp = s:option(ListValue,
			"txpower", translate("Transmit Power"), "dBm")
		tp.rmempty = true
		tp.default = tx_power_cur
		function tp.cfgvalue(...)
			return txpower_current(Value.cfgvalue(...), tx_power_list)
		end

		for _, p in ipairs(tx_power_list) do
			tp:value(p.driver_dbm, "%i dBm (%i mW)"
				%{ p.display_dbm, p.display_mw })
		end
	end

	s2 = m:section(NamedSection, wdev:name(), "wifi-device", translate("Advanced Settings"))
	s2.addremove = false

	hwmode = s2:option(ListValue, "hwmode", translate("Mode"))
	hwmode:value("", translate("auto"))
	if hw_modes.b then hwmode:value("11b", "802.11b") end
	if hw_modes.g then hwmode:value("11g", "802.11g") end
	if hw_modes.a then hwmode:value("11a", "802.11a") end

	if htcaps then
		if hw_modes.g and hw_modes.n then hwmode:value("11ng", "802.11g+n") end
		if hw_modes.a and hw_modes.n then hwmode:value("11na", "802.11a+n") end

		htmode = s2:option(ListValue, "htmode", translate("HT mode"))
		htmode:depends("hwmode", "11na")
		htmode:depends("hwmode", "11ng")
		htmode:value("HT20", "20MHz")
		htmode:value("HT40-", translate("40MHz 2nd channel below"))
		htmode:value("HT40+", translate("40MHz 2nd channel above"))

		noscan = s2:option(Flag, "noscan", translate("Force 40MHz mode"),
			translate("Always use 40MHz channels even if the secondary channel overlaps. Using this option does not comply with IEEE 802.11n-2009!"))
		noscan:depends("htmode", "HT40+")
		noscan:depends("htmode", "HT40-")
		noscan.default = noscan.disabled

		--htcapab = s:taboption("advanced", DynamicList, "ht_capab", translate("HT capabilities"))
		--htcapab:depends("hwmode", "11na")
		--htcapab:depends("hwmode", "11ng")
	end

	local cl = iw and iw.countrylist
	if cl and #cl > 0 then
		cc = s2:option(ListValue, "country", translate("Country Code"), translate("Use ISO/IEC 3166 alpha2 country codes."))
		cc.default = tostring(iw and iw.country or "00")
		for _, c in ipairs(cl) do
			cc:value(c.alpha2, "%s - %s" %{ c.alpha2, c.name })
		end
	else
		s2:option(Value, "country", translate("Country Code"), translate("Use ISO/IEC 3166 alpha2 country codes."))
	end

	-- s2:option(Value, "distance", translate("Distance Optimization"),
	-- 	translate("Distance to farthest network member in meters."))

	-- external antenna profiles
	local eal = iw and iw.extant
	if eal and #eal > 0 then
		ea = s2:option(ListValue, "extant", translate("Antenna Configuration"))
		for _, eap in ipairs(eal) do
			ea:value(eap.id, "%s (%s)" %{ eap.name, eap.description })
			if eap.selected then
				ea.default = eap.id
			end
		end
	end

	s2:option(Value, "frag", translate("Fragmentation Threshold"))
	s2:option(Value, "rts", translate("RTS/CTS Threshold"))
end


------------------- Madwifi Device ------------------

if hwtype == "qcawifi" then
	-- tp = s:option(
	-- 	(#tx_power_list > 0) and ListValue or Value,
	-- 	"txpower", translate("Transmit Power"), "dBm")

	-- tp.rmempty = true
	-- tp.default = tx_power_cur

	-- function tp.cfgvalue(...)
	-- 	return txpower_current(Value.cfgvalue(...), tx_power_list)
	-- end

	-- for _, p in ipairs(tx_power_list) do
	-- 	tp:value(p.driver_dbm, "%i dBm (%i mW)"
	-- 		%{ p.display_dbm, p.display_mw })
	-- end

	txpower = s:option(ListValue, "txpower", translate("Transmit Power"))

	--txpower option--	
				--setSelectOption("wifi_file","txpower",txpower)
				txpower:value("0","Auto")
				txpower:value("11","11 dBm")
				txpower:value("12","12 dBm")
				txpower:value("13","13 dBm")
				txpower:value("14","14 dBm")
				txpower:value("15","15 dBm")
				txpower:value("16","16 dBm")
				txpower:value("17","17 dBm")
				txpower:value("18","18 dBm")
				txpower:value("19","19 dBm")
				txpower:value("20","20 dBm")
				txpower:value("21","21 dBm")
				txpower:value("22","22 dBm")
				txpower:value("23","23 dBm")
				txpower:value("24","24 dBm")
				txpower:value("25","25 dBm")
				txpower:value("26","26 dBm")
				txpower:value("27","27 dBm")
				txpower:value("28","28 dBm")
				-- txpower.default = m.uci:get("wireless","wifi0","txpower")


	-- s2 = m:section(NamedSection, wdev:name(), "wifi-device", translate("Advanced Settings"))
	-- s2.addremove = false

	--hwmmode option--	
	hwmode = s:option(ListValue, "hwmode", translate("Mode"))
	-- mode:value("", translate("auto"))
	-- if hw_modes.b then mode:value("11b", "802.11b") end
	-- if hw_modes.g then mode:value("11g", "802.11g") end
	-- if hw_modes.a then mode:value("11a", "802.11a") end
	-- if hw_modes.g then mode:value("11bg", "802.11b+g") end
	-- if hw_modes.g then mode:value("11gst", "802.11g + Turbo") end
	-- if hw_modes.a then mode:value("11ast", "802.11a + Turbo") end
	-- mode:value("fh", translate("Frequency Hopping"))


	--setSelectOption("wifi_file","hwmode",hwmode)
	hwmode:value("11ng",  "802.11 B/G/N")  
	hwmode:value("11bg",  "802.11 B/G")
	hwmode:value("11b", "802.11 B")
	hwmode:value("11g", "802.11 G")    	
	hwmode:value("11n", "802.11 N (2.4GHz)")  
	-- mode.default = m.uci:get("wireless","wifi0","hwmode")



	-- s2:option(Flag, "diversity", translate("Diversity")).rmempty = false

	-- if not nsantenna then
	-- 	ant1 = s2:option(ListValue, "txantenna", translate("Transmitter Antenna"))
	-- 	ant1.widget = "radio"
	-- 	ant1.orientation = "horizontal"
	-- 	ant1:depends("diversity", "")
	-- 	ant1:value("0", translate("auto"))
	-- 	ant1:value("1", translate("Antenna 1"))
	-- 	ant1:value("2", translate("Antenna 2"))

	-- 	ant2 = s2:option(ListValue, "rxantenna", translate("Receiver Antenna"))
	-- 	ant2.widget = "radio"
	-- 	ant2.orientation = "horizontal"
	-- 	ant2:depends("diversity", "")
	-- 	ant2:value("0", translate("auto"))
	-- 	ant2:value("1", translate("Antenna 1"))
	-- 	ant2:value("2", translate("Antenna 2"))

	-- else -- NanoFoo
	-- 	local ant = s2:option(ListValue, "antenna", translate("Transmitter Antenna"))
	-- 	ant:value("auto")
	-- 	ant:value("vertical")
	-- 	ant:value("horizontal")
	-- 	ant:value("external")
	-- end

	-- -- s2:option(Value, "distance", translate("Distance Optimization"),
	-- -- 	translate("Distance to farthest network member in meters."))
	-- s2:option(Value, "regdomain", translate("Regulatory Domain"))
		rate = s:option(ListValue, "rate", translate("Data Rate"))
	-- s2:option(Flag, "outdoor", translate("Outdoor Channels"))
	--s:option(Flag, "nosbeacon", translate("Disable HW-Beacon timer"))
			
	--rate option--	
	rate:value("0x0", "Auto", {hwmode="11b"},{hwmode="11g"}, {hwmode="11a"},{hwmode="11n"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("", "Auto", {hwmode="11ac"})
    rate:value("0x1b1b1b1b", "1Mbps", {hwmode="11b"}, {hwmode="11bg"}, {hwmode="11ng"})
    rate:value("0x1a1a1a1a", "2Mbps", {hwmode="11b"}, {hwmode="11bg"}, {hwmode="11ng"})
    rate:value("0x19191919", "5.5Mbps", {hwmode="11b"} ,{hwmode="11bg"}, {hwmode="11ng"})	        
    rate:value("0x0b0b0b0b",  "6Mbps",  {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
    rate:value("0x0f0f0f0f",  "9Mbps",  {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
    rate:value("0x18181818", "11Mbps", {hwmode="11b"}, {hwmode="11bg"}, {hwmode="11ng"})
    rate:value("0x0a0a0a0a", "12Mbps", {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x0e0e0e0e", "18Mbps", {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x09090909", "24Mbps", {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x0d0d0d0d", "36Mbps", {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x08080808", "48Mbps", {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x0c0c0c0c", "54Mbps", {hwmode="11g"}, {hwmode="11a"}, {hwmode="11bg"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x80808080", "mcs0", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0", "mcs0", {hwmode="11ac"})
	rate:value("1", "mcs1", {hwmode="11ac"})
	rate:value("0x81818181", "mcs1", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("2", "mcs2", {hwmode="11ac"})
	rate:value("0x82828282", "mcs2", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("3", "mcs3", {hwmode="11ac"})
	rate:value("0x83838383", "mcs3", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("4", "mcs4", {hwmode="11ac"})
	rate:value("0x84848484", "mcs4", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("5", "mcs5", {hwmode="11ac"})
	rate:value("0x85858585", "mcs5", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("6", "mcs6", {hwmode="11ac"})
	rate:value("0x86868686", "mcs6", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("7", "mcs7", {hwmode="11ac"})
	rate:value("0x87878787", "mcs7", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("8", "mcs8", {hwmode="11ac"})
	rate:value("0x88888888", "mcs8", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("9", "mcs9", {hwmode="11ac"})
	rate:value("0x89898989", "mcs9", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x8a8a8a8a", "mcs10", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x8b8b8b8b", "mcs11", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x8c8c8c8c", "mcs12", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x8d8d8d8d", "mcs13", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x8e8e8e8e", "mcs14", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x8f8f8f8f", "mcs15", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x90909090", "mcs16", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x91919191", "mcs17", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x92929292", "mcs18", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x93939393", "mcs19", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x94949494", "mcs20", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x95959595", "mcs21", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x96969696", "mcs22", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	rate:value("0x97979797", "mcs23", {hwmode="11n"}, {hwmode="11ng"}, {hwmode="11na"})
	-- rate.default = m.uci:get("wireless","wifi0","rate")
	
	if wdev:name() ==  "wifi1" then
		-- sc = s2:option(Value, "country", translate("Country Code"))
		sc = s:option(DummyValue, "country")
		sc.template = "admin_network/wifi_countrylist"
		-- st.ifname   = arg[1]
	end

end



------------------- Broadcom Device ------------------

if hwtype == "broadcom" then
	tp = s:option(
		(#tx_power_list > 0) and ListValue or Value,
		"txpower", translate("Transmit Power"), "dBm")

	tp.rmempty = true
	tp.default = tx_power_cur

	function tp.cfgvalue(...)
		return txpower_current(Value.cfgvalue(...), tx_power_list)
	end

	for _, p in ipairs(tx_power_list) do
		tp:value(p.driver_dbm, "%i dBm (%i mW)"
			%{ p.display_dbm, p.display_mw })
	end
	s2 = m:section(NamedSection, wdev:name(), "wifi-device", translate("Advanced Settings"))
	-- s2.addremove = false
	mode = s2:option(ListValue, "hwmode", translate("Mode"))
	mode:value("11bg", "802.11b+g")
	mode:value("11b", "802.11b")
	mode:value("11g", "802.11g")
	mode:value("11gst", "802.11g + Turbo")

	-- ant1 = s2:option(ListValue, "txantenna", translate("Transmitter Antenna"))
	-- ant1.widget = "radio"
	-- ant1:depends("diversity", "")
	-- ant1:value("3", translate("auto"))
	-- ant1:value("0", translate("Antenna 1"))
	-- ant1:value("1", translate("Antenna 2"))

	-- ant2 = s2:option(ListValue, "rxantenna", translate("Receiver Antenna"))
	-- ant2.widget = "radio"
	-- ant2:depends("diversity", "")
	-- ant2:value("3", translate("auto"))
	-- ant2:value("0", translate("Antenna 1"))
	-- ant2:value("1", translate("Antenna 2"))

	-- s2:option(Flag, "frameburst", translate("Frame Bursting"))

	-- s2:option(Value, "distance", translate("Distance Optimization"))
	--s:option(Value, "slottime", translate("Slot time"))

	s2:option(Value, "country", translate("Country Code"))
	-- s2:option(Value, "maxassoc", translate("Connection Limit"))
end


--------------------- HostAP Device ---------------------

if hwtype == "prism2" then
	s2:option(Value, "txpower", translate("Transmit Power"), "att units").rmempty = true

	-- s2:option(Flag, "diversity", translate("Diversity")).rmempty = false

	-- s2:option(Value, "txantenna", translate("Transmitter Antenna"))
	-- s2:option(Value, "rxantenna", translate("Receiver Antenna"))
end

----------------------- Interface -----------------------

s3 = m:section(NamedSection, wnet.sid, "wifi-iface", translate("Interface Configuration<br><br>General Setup"))
ifsection = s3
s3.addremove = false
s3.anonymous = true
s3.defaults.device = wdev:name()

-- s:tab("general", translate("General Setup"))
-- s:tab("encryption", translate("Wireless Security"))
-- s:tab("macfilter", translate("MAC-Filter"))
-- s:tab("advanced", translate("Advanced Settings"))

s3:option(Value, "ssid", translate("<abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))

-- mode = s3:option(ListValue, "mode", translate("Mode"))
mode = s3:option(DummyValue,"mode", translate("Mode"))
mode.value = "Access Point"

-- mode.override_values = true
-- mode:value("ap", translate("Access Point"))
-- mode:value("sta", translate("Client"))
-- mode:value("adhoc", translate("Ad-Hoc"))

bssid = s3:option(Value, "bssid", translate("<abbr title=\"Basic Service Set Identifier\">BSSID</abbr>"))


-------------------- MAC80211 Interface ----------------------

if hwtype == "mac80211" then
	-- if fs.access("/usr/sbin/iw") then
	-- 	mode:value("mesh", "802.11s")
	-- end

	-- mode:value("ahdemo", translate("Pseudo Ad-Hoc (ahdemo)"))
	-- mode:value("monitor", translate("Monitor"))
	bssid:depends({mode="adhoc"})
	bssid:depends({mode="sta"})
	bssid:depends({mode="sta-wds"})

	s6 = m:section(NamedSection, wnet.sid, "wifi-iface", translate("MAC-Filter"))
	ifsection = s6
	s6.addremove = false
	s6.anonymous = true
	s6.defaults.device = wdev:name()

	mp = s6:option(ListValue, "macfilter", translate("MAC-Address Filter"))
	mp:depends({mode="ap"})
	mp:depends({mode="ap-wds"})
	mp:value("", translate("disable"))
	mp:value("allow", translate("Allow listed only"))
	mp:value("deny", translate("Allow all except listed"))

	ml = s6:option(DynamicList, "maclist", translate("MAC-List"))
	ml.datatype = "macaddr"
	ml:depends({macfilter="allow"})
	ml:depends({macfilter="deny"})
	nt.mac_hints(function(mac, name) ml:value(mac, "%s (%s)" %{ mac, name }) end)

	-- mode:value("ap-wds", "%s (%s)" % {translate("Access Point"), translate("WDS")})
	-- mode:value("sta-wds", "%s (%s)" % {translate("Client"), translate("WDS")})

	-- function mode.write(self, section, value)
	-- 	if value == "ap-wds" then
	-- 		ListValue.write(self, section, "ap")
	-- 		m.uci:set("wireless", section, "wds", 1)
	-- 	elseif value == "sta-wds" then
	-- 		ListValue.write(self, section, "sta")
	-- 		m.uci:set("wireless", section, "wds", 1)
	-- 	else
	-- 		ListValue.write(self, section, value)
	-- 		m.uci:delete("wireless", section, "wds")
	-- 	end
	-- end

	-- function mode.cfgvalue(self, section)
	-- 	local mode = ListValue.cfgvalue(self, section)
	-- 	local wds  = m.uci:get("wireless", section, "wds") == "1"

	-- 	if mode == "ap" and wds then
	-- 		return "ap-wds"
	-- 	elseif mode == "sta" and wds then
	-- 		return "sta-wds"
	-- 	else
	-- 		return mode
	-- 	end
	-- end

	hidden = s3:option(Flag, "hidden", translate("Hide <abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))
	hidden:depends({mode="ap"})
	hidden:depends({mode="ap-wds"})

	wmm = s3:option(Flag, "wmm", translate("WMM Mode"))
	wmm:depends({mode="ap"})
	wmm:depends({mode="ap-wds"})
	wmm.default = wmm.enabled
end

-------------------- Madwifi Interface ----------------------

if hwtype == "qcawifi" then
	-- mode:value("ahdemo", translate("Pseudo Ad-Hoc (ahdemo)"))
	-- mode:value("monitor", translate("Monitor"))
	-- mode:value("ap-wds", "%s (%s)" % {translate("Access Point"), translate("WDS")})
	-- mode:value("sta-wds", "%s (%s)" % {translate("Client"), translate("WDS")})
	-- mode:value("wds", translate("Static WDS"))

	-- function mode.write(self, section, value)
	-- 	if value == "ap-wds" then
	-- 		ListValue.write(self, section, "ap")
	-- 		m.uci:set("wireless", section, "wds", 1)
	-- 	elseif value == "sta-wds" then
	-- 		ListValue.write(self, section, "sta")
	-- 		m.uci:set("wireless", section, "wds", 1)
	-- 	else
	-- 		ListValue.write(self, section, value)
	-- 		m.uci:delete("wireless", section, "wds")
	-- 	end
	-- end

	-- function mode.cfgvalue(self, section)
	-- 	local mode = ListValue.cfgvalue(self, section)
	-- 	local wds  = m.uci:get("wireless", section, "wds") == "1"

	-- 	if mode == "ap" and wds then
	-- 		return "ap-wds"
	-- 	elseif mode == "sta" and wds then
	-- 		return "sta-wds"
	-- 	else
	-- 		return mode
	-- 	end
	-- end

	s4 = m:section(NamedSection, wnet.sid, "wifi-iface", translate("Advanced Settings"))
	ifsection = s4
	s4.addremove = false
	s4.anonymous = true
	s4.defaults.device = wdev:name()

	-- wdssep = s4:option(Flag, "wdssep", translate("Separate WDS"))


	-- s4:option(Flag, "doth", "802.11h")
	-- hidden = s3:option(Flag, "hidden", translate("Hide <abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))

	isolate = s4:option(Flag, "isolate", translate("Separate Clients"),
	translate("Prevents client-to-client communication"))

	-- s4:option(Flag, "bgscan", translate("Background Scan"))
	
	s6 = m:section(NamedSection, wnet.sid, "wifi-iface", translate("MAC-Filter"))
	ifsection = s6
	s6.addremove = false
	s6.anonymous = true
	s6.defaults.device = wdev:name()
	
	mp = s6:option(ListValue, "macpolicy", translate("MAC-Address Filter"))
	mp:value("", translate("disable"))
	mp:value("allow", translate("Allow listed only"))
	mp:value("deny", translate("Allow all except listed"))

	ml = s6:option(DynamicList, "maclist", translate("MAC-List"))
	ml.datatype = "macaddr"
	ml:depends({macpolicy="allow"})
	ml:depends({macpolicy="deny"})
	nt.mac_hints(function(mac, name) ml:value(mac, "%s (%s)" %{ mac, name }) end)

	-- s4:option(Value, "rate", translate("Transmission Rate"))
	-- s4:option(Value, "mcast_rate", translate("Multicast Rate"))
	s4:option(Value, "frag", translate("Fragmentation Threshold"))
	s4:option(Value, "rts", translate("RTS/CTS Threshold"))
	-- s4:option(Value, "minrate", translate("Minimum Rate"))
	-- s4:option(Value, "maxrate", translate("Maximum Rate"))
	-- s4:option(Flag, "compression", translate("Compression"))

	-- s4:option(Flag, "bursting", translate("Frame Bursting"))
	-- s4:option(Flag, "turbo", translate("Turbo Mode"))
	-- s4:option(Flag, "ff", translate("Fast Frames"))

	-- s4:option(Flag, "wmm", translate("WMM Mode"))
	-- s4:option(Flag, "xr", translate("XR Support"))
	-- s4:option(Flag, "ar", translate("AR Support"))

	-- local swm = s4:option(Flag, "sw_merge", translate("Disable HW-Beacon timer"))
	-- swm:depends({mode="adhoc"})

	-- local nos = s4:option(Flag, "nosbeacon", translate("Disable HW-Beacon timer"))
	-- nos:depends({mode="sta"})
	-- nos:depends({mode="sta-wds"})

	-- local probereq = s4:option(Flag, "probereq", translate("Do not send probe responses"))
	-- probereq.enabled  = "0"
	-- probereq.disabled = "1"

end

-------------------- Broadcom Interface ----------------------

if hwtype == "broadcom" then
	-- mode:value("wds", translate("WDS"))
	-- mode:value("monitor", translate("Monitor"))

	hidden = s3:option(Flag, "hidden", translate("Hide <abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))
	hidden:depends({mode="ap"})
	hidden:depends({mode="adhoc"})
	hidden:depends({mode="wds"})

	s4 = m:section(NamedSection, wnet.sid, "wifi-iface", translate("Advanced Settings"))
	ifsection = s4
	s4.addremove = false
	s4.anonymous = true
	s4.defaults.device = wdev:name()

	isolate = s4:option(Flag, "isolate", translate("Separate Clients"),
	 translate("Prevents client-to-client communication"))
	isolate:depends({mode="ap"})

	s4:option(Flag, "doth", "802.11h")
	s4:option(Flag, "wmm", translate("WMM Mode"))

	bssid:depends({mode="wds"})
	bssid:depends({mode="adhoc"})
end


----------------------- HostAP Interface ---------------------

if hwtype == "prism2" then
	-- mode:value("wds", translate("WDS"))
	-- mode:value("monitor", translate("Monitor"))

	hidden = s3:option(Flag, "hidden", translate("Hide <abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))
	hidden:depends({mode="ap"})
	hidden:depends({mode="adhoc"})
	hidden:depends({mode="wds"})

	bssid:depends({mode="sta"})

	s6 = m:section(NamedSection, wnet.sid, "wifi-iface", translate("MAC-Filter"))
	ifsection = s6
	s6.addremove = false
	s6.anonymous = true
	s6.defaults.device = wdev:name()

	mp = s6:option(ListValue, "macpolicy", translate("MAC-Address Filter"))
	mp:value("", translate("disable"))
	mp:value("allow", translate("Allow listed only"))
	mp:value("deny", translate("Allow all except listed"))
	ml = s6:option(DynamicList, "maclist", translate("MAC-List"))
	ml:depends({macpolicy="allow"})
	ml:depends({macpolicy="deny"})
	nt.mac_hints(function(mac, name) ml:value(mac, "%s (%s)" %{ mac, name }) end)

	-- s4:option(Value, "rate", translate("Transmission Rate"))
	s4:option(Value, "frag", translate("Fragmentation Threshold"))
	s4:option(Value, "rts", translate("RTS/CTS Threshold"))
end


return m
