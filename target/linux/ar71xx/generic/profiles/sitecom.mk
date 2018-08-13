#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WLR3100
	NAME:=Sitecom WLR3100
	PACKAGES:=
endef

define Profile/WLR3100/Description
	Package set optimized for the Sitecom WLR3100.
endef

$(eval $(call Profile,WLR3100))

define Profile/WLR8100
	NAME:=Sitecom WLR8100
	PACKAGES:=
endef

define Profile/WLR8100/Description
	Package set optimized for the Sitecom WLR8100.
endef

$(eval $(call Profile,WLR8100))
