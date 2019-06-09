#!/bin/sh
# Simple wrapper to quickly run systemd-nspawn containers
# (If you want to use it for other caontainers, not systemd-nspawn, please make a pull request)
# Author: Mikhail Novosyolov <m.novosyolov@rosalinux.ru>
# License: MIT

CMD_NSPAWN="systemd-nspawn"
CMD_READELF="readelf"
CMD_TEST="test"
DIR="${DIR:-/var/lib/machines}"
X11_SOCKET_DIR="${X11_SOCKET_DIR:-/tmp/.X11-unix}"
# NW - network
NW="${NW:-1}"

SUDO_CMD="$(command -v sudo)"
if [ "$(id -u)" != "0" ]
	then if [ -x "${SUDO_CMD}" ]
		then
			# check ability to use sudo
			if ! "${SUDO_CMD}" echo test 2>&1 >/dev/null; then
				echo "Unable to use sudo, run snr from root or setup sudoers"
				exit 1
			fi
			CMD_NSPAWN="${SUDO_CMD} systemd-nspawn"
			CMD_READELF="${SUDO_CMD} readelf"
			CMD_TEST="${SUDO_CMD} test"
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

for i in "$X11_SOCKET_DIR"
do
	if $CMD_TEST -r "$i"; then
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

if [ "$NW" != 0 ]; then
	if ! echo " $OTHER " | grep -qE ' -b | --boot ' && [ "$NW" != 2 ]
		# If we are not booting the container, than network managing services won't start
		# and won't setup network, so don't bind to a network bridge, otherwise network will not work;
		# but NW=2 may be used to force always setting up the network.
		then :
		else virtual_network
	fi
fi

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
