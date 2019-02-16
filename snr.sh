#!/bin/sh
# Simple and ugly wrapper to quickly run systemd-nspawn containers
# Author: mikhailnov
# License: GPLv3

CMD="systemd-nspawn"
# from https://github.com/bigbluebutton/bigbluebutton/pull/6284
if [ "$(id -u)" != "0" ]
	then if [ -x "$(which sudo)" ]
		then CMD="$(which sudo) systemd-nspawn"
		else echo "snr must be ran as root!" && exit 1
	fi
fi

for i in "/mnt/dev" "/tmp/.X11-unix"
do
	bind_options="${bind_options} --bind=${i}"
done

case "$1" in
	* ) TARGET="$1"; shift; OTHER=" $@";;
esac

set -x
xhost +local:
$CMD --setenv=DISPLAY="${DISPLAY}" ${bind_options} -D "/mnt/${TARGET}" ${OTHER}
