require "luci.util"
require "nixio.fs"
require "luci.sys"
local m = nil

m = Map("firewall", translate("Firewall"),
	translate("The Broadband router provides extensive firewall protection by restricting connection parameters, thus limiting the risk of a hacker attack, and defending against a wide array of common attacks. However, for applications that require unrestricted access to the Internet, you can configure a specific client/server as a Demilitarized Zone (DMZ) "))

s = m:section(NamedSection, "firewall", translate(""))

en = s:option(ListValue, "enable", translate("Enable or disable Firewall module function"))
en.widget = "radio"
en.orientation = "horizontal"
en:value('1',translate("Enable"))
en:value('0',translate("Disable"))

return m
