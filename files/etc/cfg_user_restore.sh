#!/bin/sh
folder="/tmp/UserConfig"
tmpfile="/tmp/UserConfig/overlay.tar.gz"
mtd_block="$(cat /proc/mtd | grep "userconfig" | cut -d ":" -f 1 | sed -e "s/^mtd/mtdblock/g")"
# mtd_block = mtdblock5

([ -d "$folder" ] || (rm -rf "$folder" && mkdir -p "$folder")) && {
	[ -n "$mtd_block" ] && mount -t jffs2 "/dev/$mtd_block" "$folder"
}

if [ -f "$tmpfile" ];
then
	gunzip -t -f "$tmpfile" && \
	tar -zxvf "$tmpfile" -C/ && \
	echo "===========  config restored  ===========" > /dev/console
	umount "/dev/$mtd_block"
	reboot
else
	echo "===========  no user_config.tar.gz, do nothing  ===========" > /dev/console
fi
