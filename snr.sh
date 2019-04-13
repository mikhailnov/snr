#!/bin/sh
# Simple and ugly wrapper to quickly run systemd-nspawn containers
# Author: mikhailnov
# License: GPLv3

CMD="systemd-nspawn"
DIR="${DIR:-/var/lib/machines}"

# from https://github.com/bigbluebutton/bigbluebutton/pull/6284
if [ "$(id -u)" != "0" ]
	then if [ -x "$(which sudo)" ]
		then CMD="$(which sudo) systemd-nspawn"
		else echo "snr must be ran as root!" && exit 1
	fi
fi

# http://ludiclinux.com/Nspawn-Steam-Container/
for i in \
	"/mnt/dev" \
	"/dev/dri" \
	"/dev/shm" \
	"/dev/snd" \
	"/dev/nvidia0" \
	"/dev/nvidiactl" \
	"/dev/nvidia-modeset" \
	"/run/user/${UID}/pulse"
do
	if [ -r "$i" ]; then
		bind_options="${bind_options} --bind=${i}"
	fi
done

for i in "/tmp/.X11-unix"
do
	if [ -r "$i" ]; then
		bind_options="${bind_options} --bind-ro=${i}"
	fi
done

case "$1" in
	* ) TARGET="$1"; shift; OTHER=" $@";;
esac

set -x
xhost +local:
$CMD \
	--setenv=DISPLAY="${DISPLAY}" \
	--setenv=LC_ALL="${LANG}" \
	${bind_options} \
	-D "${DIR}/${TARGET}" \
	${OTHER}
