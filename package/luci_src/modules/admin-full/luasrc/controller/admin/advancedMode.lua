module("luci.controller.admin.advancedMode", package.seeall)

function index()
	local uci = require("luci.model.uci").cursor()
	entry({"admin", "home"}, alias("admin", "status", "overview"), _("Home"), 50)
	entry({"admin", "status","overview"}, template("admin_status/home"),nil)
	
	entry({"admin", "wifi"}, alias("admin", "wifi", "overview"), _("Wi-Fi"), 60)	

	entry({"admin", "interfaces"}, alias("admin", "interfaces", "overview"), _("Interfaces"), 70)
	
	--entry({"admin", "interfaces", "create_interface"}, template("fake"), _("Create interface"), 2)
	entry({"admin", "interfaces", "vlan"}, template("fake"), _("VLan"), 5)
	entry({"admin", "interfaces", "dhcp_dns"}, cbi("admin_network/advanced_dhcp"), _("DHCP and DNS"), 6)
	entry({"admin", "interfaces", "routes"}, cbi("admin_network/advanced_routes"), _("Routes"), 6)

	if nixio.fs.access("/etc/config/fstab") then
		entry({"admin", "filesystems"}, alias("admin", "filesystems", "mount_points"), _("Filesystems"), 80)
		entry({"admin", "filesystems", "mount_points"}, cbi("admin_system/fstab_fs"), _("Mount Points"), 50)
		entry({"admin", "filesystems", "mount_points", "mount"}, cbi("admin_system/fstab_fs/mount_fs"), nil).leaf = true
		entry({"admin", "filesystems", "mount_points", "swap"},  cbi("admin_system/fstab_fs/swap_fs"),  nil).leaf = true
	end
	if nixio.fs.access("/bin/opkg") then
		entry({"admin", "apps"}, alias("admin", "apps", "software"), _("Apps"), 90)
		entry({"admin", "apps", "software"}, call("action_packages_apps"), _("Software"), 1)
		--entry({"admin", "apps", "installed_packages"}, template("fake"), _("Installed Packages"), 2)
		--entry({"admin", "apps", "available_packages"}, template("fake"), _("Available Packages"), 3)
	end


	entry({"admin", "firewall"}, alias("admin", "firewall", "dmz"), _("Firewall"), 100)
	--entry({"admin", "firewall", "status"}, template("fake"), _("Status"), 1)
	--entry({"admin", "firewall", "general_settings"}, template("fake"), _("General Settings"), 2)
	--entry({"admin", "firewall", "port_forwarding"}, template("fake"), _("Port Forwarding"), 3)
	entry({"admin", "firewall", "enable"}, cbi("admin_network/firewall_enable"), _("Enable"), 4)
	entry({"admin", "firewall", "dmz"}, call("firewall_dmz"), _("DMZ"), 5)
	entry({"admin", "firewall", "dos"}, call("firewall_dos"), _("Dos"), 6)
	entry({"admin", "firewall", "access"}, call("firewall_access"), _("Access"), 7)
	entry({"admin", "firewall", "url_block"}, call("firewall_url_block"), _("URL block"), 8)
	entry({"admin", "firewall", "virtual_server"}, call("firewall_virtual_server"), _("Virtual Server"), 9)


	entry({"admin", "task_manager"}, alias("admin", "task_manager", "system_logs"), _("Task manager"), 110)
	entry({"admin", "task_manager", "system_logs"}, call("action_syslog"), _("System logs"), 1)
	entry({"admin", "task_manager", "kernel_log"}, call("action_dmesg"), _("Kernel log"), 2)
	entry({"admin", "task_manager", "processes"}, cbi("admin_status/processes_sc"), _("Processes"), 3)
	entry({"admin", "task_manager", "realtime_load"}, template("admin_status/load_sc"), _("Realtime Load"), 4)
	entry({"admin", "status", "realtime", "load_status"}, call("action_load")).leaf = true

	entry({"admin", "administration"}, alias("admin", "administration", "system_properties"), _("Administration"), 120)		
	entry({"admin", "administration", "system_properties"}, cbi("admin_system/advanced_system"), _("System properties"), 1)
	entry({"admin", "administration", "administration"}, cbi("admin_system/advanced_admin"), _("Administration"), 2)
	entry({"admin", "administration", "Backup_Flash_Firmware"},  call("action_flashops"), _("Backup / Flash Firmware"), 3)
	if nixio.fs.access("/sys/class/leds") then
		entry({"admin", "administration", "led_configuration"}, cbi("admin_system/advanced_leds"), _("LED Configuration"), 60)
	end

	entry({"admin", "toolbox"}, alias("admin", "toolbox", "wol"), _("ToolBox"), 130)
	if nixio.fs.access("/etc/config/etherwake") then
		entry({"admin", "toolbox", "wol"}, cbi("wol_model"), _("WOL"),1)
   	end
   	if  nixio.fs.access("/etc/config/ddns") then
        entry({"admin", "toolbox", "ddns"}, cbi("ddns_sc/ddns_model"), _("DDNS"),2)       
    end



		local uci = require("luci.model.uci").cursor()
		local has_wifi = false

		uci:foreach("wireless", "wifi-device",
			function(s)
				has_wifi = true
				return false
			end)

		if has_wifi then
			page = entry({"admin", "network", "wireless_join"}, call("wifi_join"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_add"}, call("wifi_add"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_delete"}, call("wifi_delete"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_status"}, call("wifi_status"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_reconnect"}, call("wifi_reconnect"), nil)
			page.leaf = true

			page = entry({"admin", "network", "wireless_shutdown"}, call("wifi_shutdown"), nil)
			page.leaf = true

			page = entry({"admin", "wifi", "overview"}, arcombine(template("admin_network/wifi_overview_sc"), cbi("admin_network/wifi_sc")), _("Overview"), 1)
			
			page.leaf = true
			page.subindex = true

			entry({"admin", "wifi", "wlan1"}, cbi("admin_network/wifi_wlan1"), _("2.4GHz WiFi"), 2)
			entry({"admin", "wifi", "wlan2"}, cbi("admin_network/wifi_wlan2"), _("5GHz WiFi"), 3)
			entry({"admin", "wifi", "wlan1_guest"}, cbi("admin_network/wifi_wlan1_guest"), nil)
			entry({"admin", "wifi", "wlan2_guest"}, cbi("admin_network/wifi_wlan2_guest"), nil)
			entry({"admin", "wifi", "ajax_getChannelList"}, call("ajax_getChannelList"), nil)
			
			if page.inreq then
				local wdev
				local net = require "luci.model.network".init(uci)
				for _, wdev in ipairs(net:get_wifidevs()) do
					local wnet
					for _, wnet in ipairs(wdev:get_wifinets()) do
						entry(
							{"admin", "wifi", "overview", wnet:id()},
							alias("admin", "wifi", "overview"),
							wdev:name() .. ": " .. wnet:shortname()
						)
					end
				end
			end
		end

		page = entry({"admin", "network", "iface_add"}, cbi("admin_network/iface_add"), nil)
		page.leaf = true

		page = entry({"admin", "network", "iface_delete"}, call("iface_delete"), nil)
		page.leaf = true

		page = entry({"admin", "network", "iface_status"}, call("iface_status"), nil)
		page.leaf = true

		page = entry({"admin", "network", "iface_reconnect"}, call("iface_reconnect"), nil)
		page.leaf = true

		page = entry({"admin", "network", "iface_shutdown"}, call("iface_shutdown"), nil)
		page.leaf = true


		page = entry({"admin", "interfaces", "overview"}, arcombine(cbi("admin_network/network_sc"), cbi("admin_network/ifaces_sc")), _("Overview"), 1)
		page.leaf   = true
		page.subindex = true
		page = entry({"admin", "interfaces", "lan"}, call("lan"),_("Lan"), 3)
		page.leaf   = true
		page = entry({"admin", "interfaces", "wan"}, call("wan"),_("Wan"), 4 )
		page.leaf   = true
		page = entry({"admin", "interfaces", "wan6"}, call("wan6"),_("Wan6"), 5 )
		page.leaf   = true
		-- if page.inreq then
		-- 	uci:foreach("network", "interface",
		-- 		function (section)
		-- 			local ifc = section[".name"]
		-- 			if ifc ~= "loopback" then
		-- 				entry({"admin", "network", "network", ifc},
		-- 				true, ifc:upper())
		-- 			end
		-- 		end)
		-- end

		local has_vlan = false

		uci:foreach("network", "switch",
			function(s)
				has_vlan = true
				return false
			end)
		
		if has_vlan then
			page  = node("admin", "interfaces", "vlan")
			page.target = cbi("admin_network/vlan_sc")
			page.title  = _("Switch")
			page.order  = 5

			page = entry({"admin", "network", "switch_status"}, call("switch_status"), nil)
			page.leaf = true
		end

end

function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end

	function firewall_dmz()
		local uci = luci.model.uci.cursor()
		for k, v in pairs(luci.http.formvaluetable("cbid")) do
			--luci.util.exec("echo "..k.."	"..v.." > /dev/ttyS0")
			local tmp = {}
			tmp =  luci.util.split(k,".")
			--luci.util.exec("echo "..tmp[1].."	"..tmp[2].."	"..tmp[3].."	"..v.." > /dev/ttyS0")
		 	uci:set(tmp[1],tmp[2],tmp[3],v)
	  		uci:save(tmp[1])
	  		uci:commit(tmp[1])	
		end	
		luci.template.render("admin_firewall/dmz")
	end	
	function firewall_dos()
		local uci = luci.model.uci.cursor()
		for k, v in pairs(luci.http.formvaluetable("cbid")) do
			--luci.util.exec("echo "..k.."	"..v.." > /dev/ttyS0")
			local tmp = {}
			tmp =  luci.util.split(k,".")
			--luci.util.exec("echo "..tmp[1].."	"..tmp[2].."	"..tmp[3].."	"..v.." > /dev/ttyS0")
		 	uci:set(tmp[1],tmp[2],tmp[3],v)
	  		uci:save(tmp[1])
	  		uci:commit(tmp[1])	
		end	
		luci.template.render("admin_firewall/dos")
	end	
function firewall_access()
		local uci = luci.model.uci.cursor()
		for k, v in pairs(luci.http.formvaluetable("cbid")) do
			--luci.util.exec("echo "..k.."	"..v.." > /dev/ttyS0")
			local tmp = {}
			tmp =  luci.util.split(k,".")
			luci.util.exec("echo "..tmp[1].."	"..tmp[2].."	"..tmp[3].."	"..v.." > /dev/ttyS0")
		 	uci:set(tmp[1],tmp[2],tmp[3],v)
	  		uci:save(tmp[1])
	  		uci:commit(tmp[1])	
		end	
		luci.template.render("admin_firewall/access")
	end	
function firewall_url_block()
		local uci = luci.model.uci.cursor()
		for k, v in pairs(luci.http.formvaluetable("cbid")) do
			--luci.util.exec("echo "..k.."	"..v.." > /dev/ttyS0")
			local tmp = {}
			tmp =  luci.util.split(k,".")
			luci.util.exec("echo "..tmp[1].."	"..tmp[2].."	"..tmp[3].."	"..v.." > /dev/ttyS0")
		 	uci:set(tmp[1],tmp[2],tmp[3],v)
	  		uci:save(tmp[1])
	  		uci:commit(tmp[1])	
		end	
		luci.template.render("admin_firewall/url_block")
	end		
function firewall_virtual_server()
		local uci = luci.model.uci.cursor()
		for k, v in pairs(luci.http.formvaluetable("cbid")) do
			--luci.util.exec("echo "..k.."	"..v.." > /dev/ttyS0")
			local tmp = {}
			tmp =  luci.util.split(k,".")
			luci.util.exec("echo "..tmp[1].."	"..tmp[2].."	"..tmp[3].."	"..v.." > /dev/ttyS0")
		 	uci:set(tmp[1],tmp[2],tmp[3],v)
	  		uci:save(tmp[1])
	  		uci:commit(tmp[1])	
		end	
		luci.template.render("admin_firewall/virtual_server")
	end			
function wifi_join()
	local function param(x)
		return luci.http.formvalue(x)
	end

	local function ptable(x)
		x = param(x)
		return x and (type(x) ~= "table" and { x } or x) or {}
	end

	local dev  = param("device")
	local ssid = param("join")

	if dev and ssid then
		local cancel  = (param("cancel") or param("cbi.cancel")) and true or false

		if cancel then
			luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless_join?device=" .. dev))
		else
			local cbi = require "luci.cbi"
			local tpl = require "luci.template"
			local map = luci.cbi.load("admin_network/wifi_add")[1]

			if map:parse() ~= cbi.FORM_DONE then
				tpl.render("header")
				map:render()
				tpl.render("footer")
			end
		end
	else
		luci.template.render("admin_network/wifi_join_sc")
	end
end

function wifi_add()
	local dev = luci.http.formvalue("device")
	local ntm = require "luci.model.network".init()

	dev = dev and ntm:get_wifidev(dev)

	if dev then
		local net = dev:add_wifinet({
			mode       = "ap",
			ssid       = "OpenWrt",
			encryption = "none"
		})

		ntm:save("wireless")
		luci.http.redirect(net:adminlink())
	end
end

function wifi_delete(network)
	local ntm = require "luci.model.network".init()
	local wnet = ntm:get_wifinet(network)
	if wnet then
		local dev = wnet:get_device()
		local nets = wnet:get_networks()
		if dev then
			luci.sys.call("env -i /sbin/wifi down %q >/dev/null" % dev:name())
			ntm:del_wifinet(network)
			ntm:commit("wireless")
			local _, net
			for _, net in ipairs(nets) do
				if net:is_empty() then
					ntm:del_network(net:name())
					ntm:commit("network")
				end
			end
			luci.sys.call("env -i /sbin/wifi up %q >/dev/null" % dev:name())
		end
	end

	luci.http.redirect(luci.dispatcher.build_url("admin/wifi/overview"))
end

function wifi_status(devs)
	local s    = require "luci.tools.status"
	local rv   = { }

	local dev
	for dev in devs:gmatch("[%w%.%-]+") do
		rv[#rv+1] = s.wifi_network(dev)
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

local function wifi_reconnect_shutdown(shutdown, wnet)
	local netmd = require "luci.model.network".init()
	local net = netmd:get_wifinet(wnet)
	local dev = net:get_device()
	if dev and net then
		luci.sys.call("env -i /sbin/wifi down >/dev/null 2>/dev/null")

		dev:set("disabled", nil)
		net:set("disabled", shutdown and 1 or nil)
		netmd:commit("wireless")

		luci.sys.call("env -i /sbin/wifi up >/dev/null 2>/dev/null")
		luci.http.status(200, shutdown and "Shutdown" or "Reconnected")

		return
	end

	luci.http.status(404, "No such radio")
end

function wifi_reconnect(wnet)
	wifi_reconnect_shutdown(false, wnet)
end

function wifi_shutdown(wnet)
	wifi_reconnect_shutdown(true, wnet)
end

function lan()
	local n = "lan"
	luci.http.redirect(luci.dispatcher.build_url("admin/interfaces/overview",n))

end

function wan()
	local n = "wan"
	luci.http.redirect(luci.dispatcher.build_url("admin/interfaces/overview",n))

end

function wan6()
	local n = "wan6"
	luci.http.redirect(luci.dispatcher.build_url("admin/interfaces/overview",n))

end

function action_syslog()
    local syslog = luci.sys.syslog()
    luci.template.render("admin_status/syslog_sc", {syslog=syslog})
end

function action_dmesg()                                                            
    local dmesg = luci.sys.dmesg()
    luci.template.render("admin_status/dmesg_sc", {dmesg=dmesg})
end
	
function action_packages_apps()
	local ipkg = require("luci.model.ipkg")
	local submit = luci.http.formvalue("submit")
	local changes = false
	local install = { }
	local remove  = { }
	local stdout  = { "" }
	local stderr  = { "" }
	local out, err

	-- Display
	local display = luci.http.formvalue("display") or "installed"

	-- Letter
	local letter = string.byte(luci.http.formvalue("letter") or "A", 1)
	letter = (letter == 35 or (letter >= 65 and letter <= 90)) and letter or 65

	-- Search query
	local query = luci.http.formvalue("query")
	query = (query ~= '') and query or nil


	-- Packets to be installed
	local ninst = submit and luci.http.formvalue("install")
	local uinst = nil

	-- Install from URL
	local url = luci.http.formvalue("url")
	if url and url ~= '' and submit then
		uinst = url
	end

	-- Do install
	if ninst then
		install[ninst], out, err = ipkg.install(ninst)
		stdout[#stdout+1] = out
		stderr[#stderr+1] = err
		changes = true
	end

	if uinst then
		local pkg
		for pkg in luci.util.imatch(uinst) do
			install[uinst], out, err = ipkg.install(pkg)
			stdout[#stdout+1] = out
			stderr[#stderr+1] = err
			changes = true
		end
	end

	-- Remove packets
	local rem = submit and luci.http.formvalue("remove")
	if rem then
		remove[rem], out, err = ipkg.remove(rem)
		stdout[#stdout+1] = out
		stderr[#stderr+1] = err
		changes = true
	end


	-- Update all packets
	local update = luci.http.formvalue("update")
	if update then
		update, out, err = ipkg.update()
		stdout[#stdout+1] = out
		stderr[#stderr+1] = err
	end


	-- Upgrade all packets
	local upgrade = luci.http.formvalue("upgrade")
	if upgrade then
		upgrade, out, err = ipkg.upgrade()
		stdout[#stdout+1] = out
		stderr[#stderr+1] = err
	end


	-- List state
	local no_lists = true
	local old_lists = false
	local tmp = nixio.fs.dir("/var/opkg-lists/")
	if tmp then
		for tmp in tmp do
			no_lists = false
			tmp = nixio.fs.stat("/var/opkg-lists/"..tmp)
			if tmp and tmp.mtime < (os.time() - (24 * 60 * 60)) then
				old_lists = true
				break
			end
		end
	end


	luci.template.render("admin_system/packages_apps", {
		display   = display,
		letter    = letter,
		query     = query,
		install   = install,
		remove    = remove,
		update    = update,
		upgrade   = upgrade,
		no_lists  = no_lists,
		old_lists = old_lists,
		stdout    = table.concat(stdout, ""),
		stderr    = table.concat(stderr, "")
	})

	-- Remove index cache
	if changes then
		nixio.fs.unlink("/tmp/luci-indexcache")
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

function iface_status(ifaces)
	local netm = require "luci.model.network".init()
	local rv   = { }

	local iface
	for iface in ifaces:gmatch("[%w%.%-_]+") do
		local net = netm:get_network(iface)
		local device = net and net:get_interface()
		if device then
			local data = {
				id         = iface,
				proto      = net:proto(),
				uptime     = net:uptime(),
				gwaddr     = net:gwaddr(),
				dnsaddrs   = net:dnsaddrs(),
				name       = device:shortname(),
				type       = device:type(),
				ifname     = device:name(),
				macaddr    = device:mac(),
				is_up      = device:is_up(),
				rx_bytes   = device:rx_bytes(),
				tx_bytes   = device:tx_bytes(),
				rx_packets = device:rx_packets(),
				tx_packets = device:tx_packets(),

				ipaddrs    = { },
				ip6addrs   = { },
				subdevices = { }
			}

			local _, a
			for _, a in ipairs(device:ipaddrs()) do
				data.ipaddrs[#data.ipaddrs+1] = {
					addr      = a:host():string(),
					netmask   = a:mask():string(),
					prefix    = a:prefix()
				}
			end
			for _, a in ipairs(device:ip6addrs()) do
				if not a:is6linklocal() then
					data.ip6addrs[#data.ip6addrs+1] = {
						addr      = a:host():string(),
						netmask   = a:mask():string(),
						prefix    = a:prefix()
					}
				end
			end
			for _, device in ipairs(net:get_interfaces() or {}) do
				data.subdevices[#data.subdevices+1] = {
					name       = device:shortname(),
					type       = device:type(),
					ifname     = device:name(),
					macaddr    = device:mac(),
					macaddr    = device:mac(),
					is_up      = device:is_up(),
					rx_bytes   = device:rx_bytes(),
					tx_bytes   = device:tx_bytes(),
					rx_packets = device:rx_packets(),
					tx_packets = device:tx_packets(),
				}
			end

			rv[#rv+1] = data
		else
			rv[#rv+1] = {
				id   = iface,
				name = iface,
				type = "ethernet"
			}
		end
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function switch_status(switches)
	local s = require "luci.tools.status"

	luci.http.prepare_content("application/json")
	luci.http.write_json(s.switch_status(switches))
end

function action_flashops()
	local sys = require "luci.sys"
	local fs  = require "luci.fs"

	local upgrade_avail = nixio.fs.access("/lib/upgrade/platform.sh")
	local reset_avail   = os.execute([[grep '"rootfs_data"' /proc/mtd >/dev/null 2>&1]]) == 0

	local restore_cmd = "tar -xzC/ >/dev/null 2>&1"
	local backup_cmd  = "sysupgrade --create-backup - 2>/dev/null"
	local image_tmp   = "/tmp/firmware.img"

	local function image_supported()
		-- XXX: yay...
		return ( 0 == os.execute(
			". /lib/functions.sh; " ..
			"include /lib/upgrade; " ..
			"platform_check_image %q >/dev/null"
				% image_tmp
		) )
	end

	local function image_checksum()
		return (luci.sys.exec("md5sum %q" % image_tmp):match("^([^%s]+)"))
	end

	local function storage_size()
		local size = 0
		if nixio.fs.access("/proc/mtd") then
			for l in io.lines("/proc/mtd") do
				local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
				if n == "linux" or n == "firmware" then
					size = tonumber(s, 16)
					break
				end
			end
		elseif nixio.fs.access("/proc/partitions") then
			for l in io.lines("/proc/partitions") do
				local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
				if b and n and not n:match('[0-9]') then
					size = tonumber(b) * 1024
					break
				end
			end
		end
		return size
	end


	local fp
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta and meta.name == "image" then
					fp = io.open(image_tmp, "w")
				else
					fp = io.popen(restore_cmd, "w")
				end
			end
			if chunk then
				fp:write(chunk)
			end
			if eof then
				fp:close()
			end
		end
	)

	if luci.http.formvalue("backup") then
		--
		-- Assemble file list, generate backup
		--
		local reader = ltn12_popen(backup_cmd)
		luci.http.header('Content-Disposition', 'attachment; filename="backup-%s-%s.tar.gz"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})
		luci.http.prepare_content("application/x-targz")
		luci.ltn12.pump.all(reader, luci.http.write)
	elseif luci.http.formvalue("restore") then
		--
		-- Unpack received .tar.gz
		--
		local upload = luci.http.formvalue("archive")
		if upload and #upload > 0 then
			luci.template.render("admin_system/applyreboot")
			luci.sys.reboot()
		end
	elseif luci.http.formvalue("image") or luci.http.formvalue("step") then
		--
		-- Initiate firmware flash
		--
		local step = tonumber(luci.http.formvalue("step") or 1)
		if step == 1 then
			if image_supported() then
				luci.template.render("admin_system/upgrade", {
					checksum = image_checksum(),
					storage  = storage_size(),
					size     = nixio.fs.stat(image_tmp).size,
					keep     = (not not luci.http.formvalue("keep"))
				})
			else
				nixio.fs.unlink(image_tmp)
				luci.template.render("admin_system/advanced_flashops", {
					reset_avail   = reset_avail,
					upgrade_avail = upgrade_avail,
					image_invalid = true
				})
			end
		--
		-- Start sysupgrade flash
		--
		elseif step == 2 then
			local keep = (luci.http.formvalue("keep") == "1") and "" or "-n"
			luci.template.render("admin_system/applyreboot", {
				title = luci.i18n.translate("Flashing..."),
				msg   = luci.i18n.translate("The system is flashing now.<br /> DO NOT POWER OFF THE DEVICE!<br /> Wait a few minutes until you try to reconnect. It might be necessary to renew the address of your computer to reach the device again, depending on your settings."),
				addr  = (#keep > 0) and "192.168.1.1" or nil
			})
			fork_exec("killall dropbear uhttpd; sleep 1; /sbin/sysupgrade %s %q" %{ keep, image_tmp })
		end
	elseif reset_avail and luci.http.formvalue("reset") then
		--
		-- Reset system
		--
		luci.template.render("admin_system/applyreboot", {
			title = luci.i18n.translate("Erasing..."),
			msg   = luci.i18n.translate("The system is erasing the configuration partition now and will reboot itself when finished."),
			addr  = "192.168.1.1"
		})
		fork_exec("killall dropbear uhttpd; sleep 1; mtd -r erase rootfs_data")
	else
		--
		-- Overview
		--
		luci.template.render("admin_system/advanced_flashops", {
			reset_avail   = reset_avail,
			upgrade_avail = upgrade_avail
		})
	end
end
	local upgrade_avail = nixio.fs.access("/lib/upgrade/platform.sh")
	local reset_avail   = os.execute([[grep '"rootfs_data"' /proc/mtd >/dev/null 2>&1]]) == 0

function iwpriv_SetCountry(wifix, country_id)
	local uci = luci.model.uci.cursor()
	luci.util.perror("country_id "..country_id)
	--country_id could not be "0", "0\n", ...etc
	if country_id=="0" or country_id==0 then country_id=uci:get("wireless","wifi0","country") end
	luci.util.perror("iwpriv "..wifix.." ,setCountryID "..country_id)
	os.execute("iwpriv %s setCountryID %s" % {wifix, country_id} )
end

function ajax_getChannelList()
        local uci = luci.model.uci.cursor()
        local country_code = luci.http.formvalue("countryCode")
        luci.util.exec("echo" .. country_code .. " > /dev/ttyS0")
        local return_array = ""
        local cfg_country = uci:get("wireless","wifi1","country")

        iwpriv_SetCountry("wifi0",country_code)
        iwpriv_SetCountry("wifi1",country_code)

        return_array = luci.util.exec([[
echo "{
    \"ChInfo2G\" :
    ["

ath2="$(iwconfig 2>/dev/null |grep -E '^ath([0]|[0|2][0-9]) '|head -n 1|awk {'printf $1'})"
ath5="$(iwconfig 2>/dev/null |grep -E '^ath([1]|[1|5][0-9]) '|head -n 1|awk {'printf $1'})" 
chan2c="$(wlanconfig ${ath2} list chan)";\
chan5c="$(wlanconfig ${ath5} list chan)";\

chan2=$(echo "$chan2c"|cut -c -38;echo "$chan2c"|cut -c 39-|sed -e "s/^  *//g"|grep ^Chan);unset chan2c; \
echo "$chan2" | \
sed -e "s/^.\{8\}\(...\)...\(....\)\(.\)\(.\).* Mhz \(....\).\(.\)..\(.*\)$/        {\"Channel\" : \"Ch\1 : \2 GHz\", \"Value\" : \"\1\"},/g"\
  -e '$s/,$//' -e 's/Ch  /Ch 0/g' -e 's/" /"/g' -e 's/" /"/g' -e 's/: 2/: 2./g'

echo "    ],
    \"ChInfo5G\" :
    ["

chan5=$(echo "$chan5c"|cut -c -49;echo "$chan5c"|cut -c 50-|sed -e "s/^  *//g"|grep ^Chan);unset chan5c; \
echo "$chan5" | \
sed -e "s/^.\{8\}\(...\)...\(....\)\(.\)\(.\).* Mhz \(....\).\(.\)..\(.\) ...\(.\) \(.\).*$/        {\"Channel\":\"Ch\1 : \2 GHz\", \"Value\":\"\1\", \"ht40\":\"\7\", \"v40\":\"\8\", \"v80\":\"\9\"},/g"\
  -e '$s/,$//' -e 's/Ch  /Ch 0/g' -e 's/" /"/g' -e 's/: 5/: 5./g' -e 's/"U"/"1"/g' -e 's/"L"/"1"/g' -e 's/"V"/"1"/g' -e 's/""/"0"/g'

echo "    ]
}"
]])
		iwpriv_SetCountry("wifi0",cfg_country)
        iwpriv_SetCountry("wifi1",cfg_country)
		luci.http.prepare_content("application/json")
        luci.http.write_json(return_array)
end