#!/bin/sh
tmpfile="/tmp/restore.gz"
#gunzip -t -f "$tmpfile" && \
#        tar -zf "$tmpfile" -xC/ && \

gunzip -t -f "$tmpfile" && {
        mkdir /tmp/restore
        tar -zf "$tmpfile" -xC /tmp/restore
        hostname=$(uci get system.@system[0].SystemName)
        config_hostname=$(uci get system.@system[0].SystemName -c /tmp/restore/etc/config)
        if [ "$hostname" == "$config_hostname" ];
        then
                tar -zf "$tmpfile" -xC /
                return 0
        else
                return 1
        fi
} && \
        echo "config restored" > /dev/ttyS0

