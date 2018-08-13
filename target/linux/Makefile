# 
# Copyright (C) 2006-2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/target.mk

export TARGET_BUILD=1

DO_LIST:=prepare compile
SHELL:= /bin/bash

CONFIG_VER:= $(shell grep CONFIG_LINUX_ ../../.config| sed s/CONFIG_LINUX_//g| cut -d '=' -f 1| sed s/_/./g)

prereq clean download prepare compile install menuconfig nconfig oldconfig update refresh: FORCE
	@+$(NO_TRACE_MAKE) -C $(BOARD) $@
	@if [ "prereq" == $@ ]; then \
		if [ -e $(TOPDIR)/SENAO/configs/kernel_config ]; then \
			cp -f $(TOPDIR)/SENAO/configs/kernel_config $(BOARD)/config-$(CONFIG_VER); \
		fi;\
	fi;
	@for s in $(DO_LIST); do \
		if [ $$s == $@ ]; then \
			if [ -e $(TOPDIR)/SENAO/configs/sysgpio.h ]; then \
				$(CP) $(TOPDIR)/SENAO/configs/sysgpio.h $(LINUX_DIR); \
				$(CP) $(TOPDIR)/SENAO/configs/sysgpio_struct.h $(LINUX_DIR); \
			fi; \
		fi; \
	done;

