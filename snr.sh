#!/bin/sh
# Simple and ugly wrapper to quickly run systemd-nspawn containers
# Author: mikhailnov
# License: GPLv3

# from https://github.com/bigbluebutton/bigbluebutton/pull/6284
if [ "$(id -u)" != "0" ]
	then if [ -x "$(which sudo)" ]
		then SUDO="$(which sudo)"
		else echo "snr must be ran as root!" && exit 1
	fi
fi

for i in "/mnt/dev" "/tmp/.X11-unix" "/media/3TB_Toshiba_BTRFS/files/tmp/rpmbuild/"
do
	bind_options="${bind_options} --bind=${i}"
done

set -x
xhost +local:
"$SUDO" systemd-nspawn --setenv=DISPLAY="${DISPLAY}" ${bind_options} -D /mnt/${1} 
