#!/bin/sh
#check_senao_image_header $senao_magic_long $senao_vendor_id $senao_product_id && return 0

senao_magic_long=$1
senao_vendor_id=$2
senao_product_id=$3

check_senao_image_header(){
	local SN_VENDOR_ID=0101
	local SN_PRODUCT_ID=006d
	[ "$senao_vendor_id" = "$SN_VENDOR_ID" -a "$senao_product_id" = "$SN_PRODUCT_ID" ] && return 0
	[ "$magic_long" = "27051956" ] && return 0
	echo "Invalid image type." >> /tmp/fw_id.txt
	return 1
}

