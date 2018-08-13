#!/bin/sh
# Copyright (C) 2006 OpenWrt.org

. /lib/auth.sh
. /etc/functions.sh
config_load network
config_get ipaddr lan ipaddr

download="/tmp/download"
eval="/tmp/eval.sh"
version="/etc/version"
firmware="/tmp/firmware.img"
backup="/tmp/backup.gz"
restore="/tmp/restore.gz"
log="$download/log.txt"

shellcmd=" \
	brctl \
	date \
	ifconfig \
	iwconfig \
	iwlist \
	iwpriv \
	logread \
	ping \
	telnet \
	traceroute \
	uci \
	uptime \
	vconfig \
	wlanconfig \
	"

show_help()
{
cat <<EOF
CLI Commands:
	arp                  Display ARP information
	config-backup        Backup config and get download URL
	config-backup-upload Backup config and upload to the remote FTP/TFTP server
	config-restore       Download config from URL and restore it
	exit                 Exit
	factory-default      Restore default config and reboot
	fwupgrade            Download firmware image from URL and upgrade it
	fwversion            Display firmware version
	help                 Help
	logfile              Save log to a file and get download URL
	logfile-upload       Save log to a file and upload to the remote FTP/TFTP server
	meminfo              Display device memory usage
	reboot               Reboot device
	rx_packets           Show WLAN received frame count
	tx_errors            Show WLAN transmitted error count
	tx_packets           Show WLAN transmitted frame count
$(for var in $shellcmd; do printf "\t$var\n"; done)
EOF
}

debug()
{
	output="/dev/ttyS0"
	dbgflag="/tmp/CLI_DEBUG"
	[ -e "$output" -a -e "$dbgflag" ] && \
		echo "$1" >/dev/ttyS0
}

read_line()
{
	echo "test" | read -R 2> /dev/null
	if [ $? -eq 0 ]; then
		read -R -rp "$1" input
	else
		read -rp "$1" input
	fi
	debug "$input"
	echo "$input"
}

priv_gate()
{
	[ "rw" = "$login_priv" ] && \
		return
	[ ! "$1" = "$login_priv" ] && {
		echo "Access denied"
		continue
	}
}

runcmd()
{
	[ -n "$1" ] && {
		[ -e "$eval" ] && \
			rm -rf "$eval"
		echo "$1" >"$eval" && \
			chmod a+x "$eval" && \
			$eval
	}
}

file_transfer()
{
	[ -n "$1" -a -n "$2" ] && {
		pattern="^\(.*\):\/\/\(\([^:]*\)\(:\(.*\)\)\{0,1\}@\)\{0,1\}\([^:/]*\)\(:\([^/]*\)\)\{0,1\}\/\(.*\)$"
		protocol=""
		username=""
		password=""
		hostname=""
		port=""
		filepath=""
		filename=""
		[ -z "$(echo "$2" | grep "'")" ] && [ -n "$(echo "$2" | grep "$pattern")" ] && {
			eval "$(echo "$2" | sed -e "s/$pattern/protocol='\1'; username='\3'; password='\5'; hostname='\6'; port='\8'; filepath='\9';/g")"
			filename="$(echo $filepath | sed -e "s/^\/\([^/]*\/\)*//g")"
		}
		[ -n "$protocol" -a -n "$hostname" -a -n "$filepath" ] && {
			cmd=""
			case "$protocol" in
				"http")
					[ "$1" = "get" ] && \
						cmd="wget"
					[ -n "$cmd" ] && {
						[ -n "$3" ] && \
							cmd="$cmd -O \"$3\""
						cmd="$cmd \"$2\""
					}
					;;
				"ftp")
					if [ "$1" = "get" ]; then
						cmd="ftpget"
					elif [ "$1" = "put" ]; then
						cmd="ftpput"
					fi
					[ -n "$cmd" ] && {
						[ -n "$username" ] && \
							cmd="$cmd -u \"$username\""
						[ -n "$password" ] && \
							cmd="$cmd -p \"$password\""
						[ -n "$port" ] && \
							cmd="$cmd -P \"$port\""
						cmd="$cmd \"$hostname\""
						if [ "$1" = "get" ]; then
							if [ -n "$3" ]; then
								cmd="$cmd \"$3\""
							else
								cmd="$cmd \"$filename\""
							fi
							cmd="$cmd \"$filepath\""
						elif [ "$1" = "put" ]; then
							cmd="$cmd \"$filepath\""
							if [ -n "$3" ]; then
								cmd="$cmd \"$3\""
							else
								cmd="$cmd \"$filename\""
							fi
						fi
					}
					;;
				"tftp")
					if [ "$1" = "get" ]; then
						cmd="tftp -g"
					elif [ "$1" = "put" ]; then
						cmd="tftp -p"
					fi
					[ -n "$cmd" ] && {
						if [ -n "$3" ]; then
							cmd="$cmd -l \"$3\""
						else
							cmd="$cmd -l \"$filename\""
						fi
						cmd="$cmd -r \"$filepath\""
						cmd="$cmd \"$hostname\""
						[ -n "$port" ] && \
							cmd="$cmd \"$port\""
					}
					;;
			esac
			[ -n "$cmd" ] && (runcmd "$cmd" 2>/dev/null >&2) && \
				return 0
		}
	}
	return 1
}

console()
{
	mkdir -p "$download"
	trap "killall eval.sh 2>&- >&2; echo" 2

	if [ "$1" = "login" ]; then
		exec /bin/ash --login
	fi

	while [ true ]; do
		input="$(read_line "> ")"
		command="$(echo "$input" | sed -e "s/^[ \t]*\([^ \t]*\)[ \t]*.*$/\1/g")"
		case "$command" in
			"")
				;;
			"arp")
				cat /proc/net/arp
				;;
			"config-backup")
				priv_gate "rw"
				printf "Download URL:\n  http://%s/cgi-bin/luci/html/CM_BackupRestore?backup=1\n" "$ipaddr"
				;;
			"config-backup-upload")
				priv_gate "rw"
				input="$(read_line "Upload config to URL: ")"
				[ -e "$backup" ] && \
					rm -rf "$backup"
				uci show luci.flash_keep | grep "keep\." | cut -d "=" -f 2 | xargs tar zcf "$backup" 2>/dev/null
				if (file_transfer "put" "$input" "$backup"); then
					printf "  MD5Sum: %s\n" "$(md5sum "$backup" | cut -d " " -f 1)"
				else
					echo "Upload failed."
				fi
				rm -rf "$backup"
				;;
			"config-restore")
				priv_gate "rw"
				input="$(read_line "Download config from URL: ")"
				[ -e "$restore" ] && \
					rm -rf "$restore"
				if (file_transfer "get" "$input" "$restore"); then
					"/etc/cfgrestore.sh" && reboot
				else
					echo "Download failed."
				fi
				;;
			"exit" | "quit" | "q")
				exit
				;;
			"factory-default")
				priv_gate "rw"
				. /etc/functions.sh && jffs2_mark_erase rootfs_data
				sync; sync; reboot
				;;
			"fwupgrade")
				priv_gate "rw"
				input="$(read_line "Download firmware image from URL: ")"
				[ -e "$firmware" ] && \
					rm -rf "$firmware"
				if (file_transfer "get" "$input" "$firmware"); then
					"/etc/cfg_backup.sh"
					"/etc/fwupgrade.sh" && reboot
				else
					echo "Upgrade failed."
				fi
				;;
			"fwversion")
				if [ -f "$version""_ui" ]; then
					grep -v "^$" "$version""_ui"
				elif [ -f "$version" ]; then
					grep -v "^$" "$version" | sed -e "s/^\([0-9]\+\(\.[0-9]\+\)\{2\}\).*$/\1/g"
				fi
				;;
			"help" | "?")
				show_help
				;;
			"logfile")
				priv_gate "rw"
				[ -e "$log" ] && \
					rm -rf "$log"
				logread >"$log"
				printf "Download log from URL:\n  http://%s%s\n  MD5Sum: %s\n" "$ipaddr" "$(echo "$log" | sed -e "s/^\/tmp//g")" "$(md5sum "$log" | cut -d " " -f 1)"
				;;
			"logfile-upload")
				priv_gate "rw"
				input="$(read_line "Upload log to URL: ")"
				[ -e "$log" ] && \
					rm -rf "$log"
				logread >"$log"
				if (file_transfer "put" "$input" "$log"); then
					printf "  MD5Sum: %s\n" "$(md5sum "$log" | cut -d " " -f 1)"
				else
					echo "Upload failed."
				fi
				rm -rf "$log"
				;;
			"meminfo")
				cat /proc/meminfo
				;;
			"reboot")
				priv_gate "rw"
				sync; sync; reboot
				;;
			"rx_packets" | "tx_errors" | "tx_packets")
				for if in $(ls "/sys/class/net/" | grep "ath[0-9]\+"); do
					printf "$if: " && cat "/sys/class/net/$if/statistics/$command"
				done
				;;
			*)
				if [ -n "$(echo "$shellcmd" | grep "	$command " 2>&-)" ]; then
					if [ -n "$(echo $input | grep "^[][)(}{0-9A-Za-z _~!@#%*:,.?+=\"\'\/\-]*$" 2>&-)" ]; then
						runcmd "$input"
					else
						echo "Invalid parameter"
					fi
				elif [ "$input" = "login" ]; then
					exec /bin/ash --login
				elif [ -z "$(echo "$input" | grep "^[ \t]*$")" ]; then
					echo "Unknown command '$command'"
				fi
				;;
		esac
	done
}

login()
{
    local module="$1"

    # dropbear has own account/password
    if [ "$module" == "dropbear" ]; then
            console
            exit
    fi
        
	count=3
	while [ $count -gt 0 ]; do
		count="$(($count-1))"
		username="$(read_line "login as: ")"
		password="$(read_line "$username's password: ")"
		clear
		if [ "$(get_username)" = "$username" -a "$(get_password)" = "$(psencry "$password")" ]; then
			login_priv="rw"
			cli_enable="$(uci get cfg_cli.@cli[0].cli_enable)" 2>/dev/null
			if [ "$cli_enable" = "1" ]; then
				cli
			fi
			exit
		else
			sleep 1
			printf "\nLogin failed, please check 'username', 'password' again. If Caps-Lock enabled?\n\n"
		fi
	done
}

if [ "$1" = "console" ]; then
        console $2
elif [ "$1" = "openssh" ]; then
    cli_enable="$(uci get cli.cli.cliEnable)" 2>/dev/null
    if [ "$cli_enable" = "1" ]; then
        cli
    else
        console
    fi
else
    # $1 for dropbear call this login.sh, and we don't need to check account/passwor
    # dropbear has own account/password
    login $1
fi
