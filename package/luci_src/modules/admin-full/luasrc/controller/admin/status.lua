--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: status.lua 9558 2012-12-18 13:58:22Z jow $
]]--

module("luci.controller.admin.status", package.seeall)

function index()
	entry({"admin", "status"}, alias("admin", "status", "overview"), _("Status"), 20).index = true
	entry({"admin", "status", "overview"}, template("admin_status/index"), _("Overview"), 1)
	entry({"admin", "status", "iptables"}, call("action_iptables"), _("Firewall"), 2).leaf = true
	entry({"admin", "status", "routes"}, template("admin_status/routes"), _("Routes"), 3)
	entry({"admin", "status", "syslog"}, call("action_syslog"), _("System Log"), 4)
	entry({"admin", "status", "dmesg"}, call("action_dmesg"), _("Kernel Log"), 5)
	entry({"admin", "status", "processes"}, cbi("admin_status/processes"), _("Processes"), 6)

	entry({"admin", "status", "realtime"}, alias("admin", "status", "realtime", "load"), _("Realtime Graphs"), 7)

	entry({"admin", "status", "realtime", "load"}, template("admin_status/load"), _("Load"), 1).leaf = true
	entry({"admin", "status", "realtime", "load_status"}, call("action_load")).leaf = true

	entry({"admin", "status", "realtime", "bandwidth"}, template("admin_status/bandwidth"), _("Traffic"), 2).leaf = true
	entry({"admin", "status", "realtime", "bandwidth_status"}, call("action_bandwidth")).leaf = true

	entry({"admin", "status", "realtime", "wireless"}, template("admin_status/wireless"), _("Wireless"), 3).leaf = true
	entry({"admin", "status", "realtime", "wireless_status"}, call("action_wireless")).leaf = true

	entry({"admin", "status", "realtime", "connections"}, template("admin_status/connections"), _("Connections"), 4).leaf = true
	entry({"admin", "status", "realtime", "connections_status"}, call("action_connections")).leaf = true

	entry({"admin", "status", "nameinfo"}, call("action_nameinfo")).leaf = true

	entry({"admin","status","statusifo"},call("statusifo"))
end

function statusifo()
	require "luci.fs"
	require "luci.tools.status"
	disp =  require "luci.dispatcher"
	local uci = require "luci.model.uci".cursor()
	local ntm = require "luci.model.network".init()
	local has_dhcp = luci.fs.access("/etc/config/dhcp")
	local has_wifi = luci.fs.stat("/etc/config/wireless")
	      has_wifi = has_wifi and has_wifi.size > 0

	if luci.http.formvalue("status") == "2" then

		local _, _, memtotal, memcached, membuffers, memfree = luci.sys.sysinfo()

			local rv = {
				memtotal   = memtotal,
				memcached  = memcached,
				membuffers = membuffers,
				memfree    = memfree
			}

		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)

		return
	end

	if luci.http.formvalue("status") == "1" then
		local ntm = require "luci.model.network".init()
		local wan = ntm:get_wannet()

		local conn_count = tonumber((
			luci.sys.exec("wc -l /proc/net/nf_conntrack") or
			luci.sys.exec("wc -l /proc/net/ip_conntrack") or
			""):match("%d+")) or 0

		local conn_max = tonumber((
			luci.sys.exec("sysctl net.nf_conntrack_max") or
			luci.sys.exec("sysctl net.ipv4.netfilter.ip_conntrack_max") or
			""):match("%d+")) or 4096

		local rv = {
			localtime  = os.date()
		}

		if wan then
			rv.wan = {
				ipaddr  = wan:ipaddr(),
				gwaddr  = wan:gwaddr(),
				netmask = wan:netmask(),
				dns     = wan:dnsaddrs(),
				expires = wan:expires(),
				uptime  = wan:uptime(),
				proto   = wan:proto(),
				ifname  = wan:ifname(),
				link    = wan:adminlink()
			}
		end

		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)

		return
	end

	local laninfo = uci:get_all("network", "lan")
	local system, model = luci.sys.sysinfo()
end

function action_syslog()
	local syslog = luci.sys.syslog()
	luci.template.render("admin_status/syslog", {syslog=syslog})
end

function action_dmesg()
	local dmesg = luci.sys.dmesg()
	luci.template.render("admin_status/dmesg", {dmesg=dmesg})
end

function action_iptables()
	if luci.http.formvalue("zero") then
		if luci.http.formvalue("zero") == "6" then
			luci.util.exec("ip6tables -Z")
		else
			luci.util.exec("iptables -Z")
		end
		luci.http.redirect(
			luci.dispatcher.build_url("admin", "status", "iptables")
		)
	elseif luci.http.formvalue("restart") == "1" then
		luci.util.exec("/etc/init.d/firewall restart")
		luci.http.redirect(
			luci.dispatcher.build_url("admin", "status", "iptables")
		)
	else
		luci.template.render("admin_status/iptables")
	end
end

function action_bandwidth(iface)
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -i %q 2>/dev/null" % iface)
	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_wireless(iface)
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -r %q 2>/dev/null" % iface)
	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_load()
	luci.http.prepare_content("application/json")

	local bwc = io.popen("luci-bwc -l 2>/dev/null")
	if bwc then
		luci.http.write("[")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end
end

function action_connections()
	local sys = require "luci.sys"

	luci.http.prepare_content("application/json")

	luci.http.write("{ connections: ")
	luci.http.write_json(sys.net.conntrack())

	local bwc = io.popen("luci-bwc -c 2>/dev/null")
	if bwc then
		luci.http.write(", statistics: [")

		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end

		luci.http.write("]")
		bwc:close()
	end

	luci.http.write(" }")
end

function action_nameinfo(...)
	local i
	local rv = { }
	for i = 1, select('#', ...) do
		local addr = select(i, ...)
		local fqdn = nixio.getnameinfo(addr)
		rv[addr] = fqdn or (addr:match(":") and "[%s]" % addr or addr)
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
