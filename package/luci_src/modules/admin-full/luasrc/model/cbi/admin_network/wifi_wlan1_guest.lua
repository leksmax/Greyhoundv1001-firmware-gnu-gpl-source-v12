
-------------------wifi 2.4G Guest Setting----------------------

local wa = require "luci.tools.webadmin"
local nw = require "luci.model.network"
local ut = require "luci.util"
local nt = require "luci.sys".net
local fs = require "nixio.fs"

arg[1] = arg[1] or "wifi0.network2"

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
-- luci.util.exec("echo " .. wnet:get("ssid") .. " >/dev/ttyS0")
-- redirect to overview page if network does not exist anymore (e.g. after a revert)
if not wnet or not wdev then
	luci.http.redirect(luci.dispatcher.build_url("admin/wifi/overview"))
	return
end


m.title = luci.util.pcdata(wnet:get_i18n())

s = m:section(NamedSection, "wifi0_guest")
s.title = translate("<br>Device Configuration")
s.addremove = false

encrContr = s:option(DummyValue,"")
encrContr.template = "admin_network/wifi_encr"

wlanEnable = s:option(ListValue,"disabled",translate("Guest Network enabled"))
wlanEnable.widget = "radio"
wlanEnable.orientation = "horizontal"
wlanEnable:value("0",translate("Enable"))
wlanEnable:value("1",translate("Disable"))

hiddenSSID = s:option(Flag, "hidden", translate("Hidden SSID"))

isolate = s:option(Flag, "isolate", translate("Client Isolation"))

s = m:section(NamedSection, "wifi0_guest")
s.title = translate("Wireless Security")
encr = s:option( ListValue, "encryption", translate("Security Mode"))
encr.override_values = true
encr.override_depends = true
encr:value("none", translate("Disabled"))
encr:value("psk", "WPA-PSK")
encr:value("psk2", "WPA2-PSK")
encr:value("psk-mixed", "WPA-PSK Mixed")

cipher = s:option(ListValue, "cipher", translate("Encryption"))
cipher:depends({encryption="psk"})
cipher:depends({encryption="psk2"})
cipher:depends({encryption="psk-mixed"})

cipher:value("ccmp", translate("AES"))

function encr.cfgvalue(self, section)
	local v = tostring(ListValue.cfgvalue(self, section))
	if v == "wep" then
		return "wep-open"
	elseif v and v:match("%+") then
		return (v:gsub("%+.+$", ""))
	elseif v == "wep-shared" or v =="wep-open" then
		return "wep"
	end
	return v
end

function encr.write(self, section, value)
	local e = tostring(encr:formvalue(section))
	local c = tostring(cipher:formvalue(section))
	if value == "wpa" or value == "wpa2"  then
		self.map.uci:delete("wireless", section, "key")
	end
	if e and (c == "tkip" or c == "ccmp" or c == "tkip+ccmp") then
		e = e .. "+" .. c
	end
	self.map:set(section, "encryption", e)
end

function cipher.cfgvalue(self, section)
	local v = tostring(ListValue.cfgvalue(encr, section))

	if m.uci:get("wireless", "wifi0", "hwmode") ~= "11n" then
		cipher:value("tkip", "TKIP")
		cipher:value("tkip+ccmp", translate("Both(TKIP+AES)"))
	end

	if v and v:match("%+") then
		v = v:gsub("^[^%+]+%+", "")
		if v == "aes" then v = "ccmp"
		elseif v == "tkip+aes" then v = "tkip+ccmp"
		elseif v == "aes+tkip" then v = "tkip+ccmp"
		elseif v == "ccmp+tkip" then v = "tkip+ccmp"
		end
	end
	return v
end

function cipher.write(self, section)
	return encr:write(section)
end

wpakey = s:option( Value, "key", translate("Passphrase"))
wpakey:depends({encryption="psk"})
wpakey:depends({encryption="psk2"})
wpakey:depends({encryption="psk+psk2"})
wpakey:depends({encryption="psk-mixed"})
wpakey.maxlength="64"
wpakey.rmempty = true

wpa_group_rekey = s:option( Value, "wpa_group_rekey", translate("Group Key Update Interval"))
wpa_group_rekey:depends({encryption="psk"})
wpa_group_rekey:depends({encryption="psk2"})
wpa_group_rekey:depends({encryption="psk-mixed"})
wpa_group_rekey.maxlength = "4"
wpa_group_rekey.default = 3600
wpa_group_rekey.rmempty = true


s = m:section(NamedSection, "wifi0_guest")
s.title = translate("MAC-Filter")
mp = s:option(ListValue, "macfilter", translate("MAC-Address Filter"))
mp:value("", translate("disable"))
mp:value("allow", translate("Allow listed only"))
mp:value("deny", translate("Allow all except listed"))

ml = s:option(DynamicList, "maclist", translate("MAC-List"))
ml.datatype = "macaddr"
ml:depends({macfilter="allow"})
ml:depends({macfilter="deny"})
nt.mac_hints(function(mac, name) ml:value(mac, "%s (%s)" %{ mac, name }) end)



--guest network Manual IP--
m1 = Map("network", "")
s1 = m1:section(NamedSection, "guest")
s1.title = translate("Manual IP Settings")
s1.addremove = false
ipaddr  = s1:option( Value, "ipaddr", translate("IP Address"))
netmask  = s1:option( Value, "netmask", translate("Subnet Mask"))


--guest network Automatic IP--
m2 = Map("dhcp", "")
s2 = m2:section(NamedSection,"guest")
s2.title = translate("Automatic DHCP Server Settings")
s2.addremove = false
start   = s2:option( Value, "start", translate("Starting IP Address"))
limit   = s2:option( Value, "limit", translate("Ending IP Address"))
dhcp_option   = s2:option( Value, "dhcp_option", translate("WINS Server IP"))


return m,m1,m2


