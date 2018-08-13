#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WX1
	NAME:=Pakedge WX1
	PACKAGES:=
endef

define Profile/WX1/Description
	Package set optimized for the Pakedge WX1.
endef

$(eval $(call Profile,WX1))
