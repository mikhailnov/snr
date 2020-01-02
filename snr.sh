#!/bin/sh
# Simple wrapper to quickly run systemd-nspawn containers
# (If you want to use it for other containers, not systemd-nspawn, please make a pull request)
# Author: Mikhail Novosyolov <m.novosyolov@rosalinux.ru>
# License: MIT

for i in "/etc/snr.conf" "${PWD}/snr.conf" 
do
	if [ -f "$i" ]; then . "$i"; fi
done

CMD_NSPAWN="systemd-nspawn"
CMD_READELF="readelf"
CMD_TEST="test"
DIR="${DIR:-/var/lib/machines}"
X11_SOCKET_DIR="${X11_SOCKET_DIR:-/tmp/.X11-unix}"
PULSE_SERVER_TARGET="${PULSE_SERVER_TARGET-/tmp/snr_PULSE_SERVER}"
# NW - network
NW="${NW:-1}"

echo_help(){
	man -P ul snr 2>/dev/null || \
		echo "See https://github.com/mikhailnov/snr for documentation"
}

case "$1" in
	-h | --help )
		echo_help
		exit
	;;
	* )
		if [ -z "$1" ]; then echo_help; exit; fi
		TARGET="$1"
		shift
		OTHER=" $@ $other_options"
	;;
esac

path_workaround(){
	# Workaround cases when some utilities, e.g. ip, are not in PATH, but still can be used
	# Example: https://bugzilla.rosalinux.ru/show_bug.cgi?id=9918
	PATH0="$PATH"
	for i in '/sbin' '/usr/sbin' '/usr/local/sbin'
	do
		if ! echo "$PATH0" | sed -e 's,:,\n,g' | grep -q "^${i}\$" \
			&& [ -d "$i" ] \
			&& [ -r "$i" ]; then
				export PATH="${i}:${PATH}"
		fi
	done
}
if ! command -v ip 2>/dev/null >/dev/null; then path_workaround; fi

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

env_setup(){
# In some cases like using sudo initially exported variables may be lost,
# so let's reexport them on each shell init
	env_file_local="$(mktemp)"
	cat > "$env_file_local" <<EOF
export DISPLAY="$DISPLAY"
export LC_ALL="$LANG"
export PULSE_SERVER="$PULSE_SERVER_TARGET"
# Fix Qt4 GUIs ("invalid Pixmap or Window parameter")
export QT_X11_NO_MITSHM=1
EOF
	bind_options="${bind_options} --bind=${env_file_local}:/etc/profile.d/90-snr-tmp.sh"
}

# http://ludiclinux.com/Nspawn-Steam-Container/
for i in \
	"/dev/dri" \
	"/dev/shm" \
	"/dev/snd" \
	"/dev/nvidia0" \
	"/dev/nvidiactl" \
	"/dev/nvidia-modeset"
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

PULSE_SERVER_LOCAL="$(LC_ALL=C pactl info | grep -i '^Server String:' | awk -F ':' '{print $NF}')"
if [ -n "$PULSE_SERVER_LOCAL" ]; then
	bind_options="${bind_options} --bind=${PULSE_SERVER_LOCAL}:${PULSE_SERVER_TARGET}"
fi

env_setup

verify_target(){
	if ! $CMD_TEST -x "$1/bin/sh"; then
		echo "$1 does not look like an OS tree, because $1/bin/sh was not found or is not executable"
		return 1
	fi
}

mk_target(){
	if [ "$(echo "$1" | head -c 1)" = "/" ] && $CMD_TEST -d "/$1"; then
		TARGET="/$1"
		verify_target "$TARGET" && return
	fi

	if $CMD_TEST -d "${PWD}/$1"; then
		TARGET="${PWD}/$1"
		verify_target "$TARGET" && return
	fi

	if $CMD_TEST -d "${DIR}/$1"; then
		TARGET="${DIR}/$1"
		verify_target "$TARGET" && return
	fi

	echo "Neither ${PWD}/$1 nor ${DIR}/$1 have been found, cannot find directory with rootfs to run!"
	exit 1
}

mk_target "$TARGET"
echo "Using OS tree in ${TARGET}"

virtual_network(){
	# virbr0 is a virtual bridge from livbirt with DHCP,
	# we can attach our containers to the same network as libvirt VMs and LXC containers.
	BRIDGE="${BRIDGE:-$(ip a | grep ': virbr' | awk -F ': ' '{print $2}' | grep -v '\-' | sort -u | head -n 1)}"
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

trap "rm -f $env_file_local" EXIT

( set -x
xhost +local:
$CMD_NSPAWN \
	--setenv=DISPLAY="${DISPLAY}" \
	--setenv=QT_X11_NO_MITSHM=1 \
	--setenv=LC_ALL="${LANG}" \
	${bind_options} \
	-D "${TARGET}" \
	${OTHER}
)
