#!/bin/sh
# Simple and ugly wrapper to quickly run systemd-nspawn containers
# Author: mikhailnov
# License: GPLv3

CMD_NSPAWN="systemd-nspawn"
CMD_READELF="readelf"
CMD_TEST="test"
DIR="${DIR:-/var/lib/machines}"
# NW - network
NW="${NW:-1}"

# from https://github.com/bigbluebutton/bigbluebutton/pull/6284
if [ "$(id -u)" != "0" ]
	then if [ -x "$(command -v sudo)" ]
		then
			CMD_NSPAWN="$(command -v sudo) systemd-nspawn"
			CMD_READELF="$(command -v sudo) readelf"
			CMD_TEST="$(command -v sudo) test"
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

mk_target(){
	if $CMD_TEST -d "${PWD}/$1"; then
		TARGET="${PWD}/$1"
		return
	fi

	if $CMD_TEST -d "${DIR}/$1"; then
		TARGET="${DIR}/$1"
		return
	fi

	echo "Neither ${PWD}/$1 nor ${DIR}/$1 have been found, cannot find directory with rootfs to run!"
	exit 1
}

case "$1" in
	* )
		mk_target "$1"
		shift
		OTHER=" $@"
		;;
esac

virtual_network(){
	# virbr0 is a virtual bridge from livbirt with DHCP,
	# we can attach our containers to the same network as libvirt VMs and LXC containers.
	BRIDGE="$(ip a | grep ': virbr' | awk -F ': ' '{print $2}' | grep -v '\-' | sort -u | head -n 1)"
	if [ -n "$BRIDGE" ]; then
		OTHER="${OTHER} --network-bridge=${BRIDGE}"
	fi
}

if [ "$NW" != 0 ]; then virtual_network; fi

# automatically set 32 bit CPU arch for containers with 32 bit OS
if $CMD_READELF -h "${TARGET}/bin/sh" | grep -q ' ELF32$'; then
	OTHER="${OTHER} --personality=x86"
fi

set -x
xhost +local:
$CMD_NSPAWN \
	--setenv=DISPLAY="${DISPLAY}" \
	--setenv=LC_ALL="${LANG}" \
	${bind_options} \
	-D "${TARGET}" \
	${OTHER}
