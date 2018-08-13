module("luci.controller.admin.basicMode", package.seeall)

function index()
	local uci = require("luci.model.uci").cursor()
	entry({"admin", "basicMode"}, alias("admin", "basicMode", "overview"), _("BasicMode"), 10).index = true
	entry({"admin", "basicMode", "overview"}, template("admin_basicMode/basicMode_Overview"), _("Overview"), 1)
	entry({"admin", "basicMode", "wi_fi_setting"}, template("admin_basicMode/wifi_Setting"), _("Wi-Fi Setting"), 2)
	entry({"admin", "basicMode", "guest_network_setting"}, template("admin_basicMode/guest_network"), _("Guest network Setting"), 3)
	entry({"admin", "basicMode", "sitecom_cloud_security"}, template("admin_basicMode/sitecom_cloud_security"), _("Sitecom Cloud Security"), 4)	
	entry({"admin", "basicMode", "ops_activation"}, template("admin_basicMode/OPS_activation"), _("OPS Activation"), 5)
	entry({"admin", "basicMode", "storage_usb_sd"}, template("admin_basicMode/storage_usb_sd"), _("Storage USB/SD"), 6)
	entry({"admin", "basicMode", "download_client"}, template("fake"), _("Download Client"), 7)
	entry({"admin", "basicMode", "print_server_airprint"}, template("admin_basicMode/print_server"), _("Print Server & Airprint"), 8)
	entry({"admin", "basicMode", "audio_music_player"}, template("admin_basicMode/audio_music_player"), _("Audio / Music Player"), 9)
	entry({"admin", "basicMode", "streamboost_technology"}, template("fake"), _("StreamBoost Technology"), 10)
	entry({"admin", "basicMode", "firmware_update"}, template("admin_basicMode/firmware_update"), _("Firmware Update"), 11)

end