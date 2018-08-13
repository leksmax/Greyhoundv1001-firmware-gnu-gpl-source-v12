#!/bin/sh
tmpfile="/tmp/backup.gz"
tar -czf "$tmpfile" -C/ etc && \
        gunzip -t -f "$tmpfile" && \
                echo "config backup" > /dev/ttyS0
