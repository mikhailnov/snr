#!/bin/sh
# wr - which repo

pi_alt(){
	lynx -dump "http://geyser.altlinux.org/en/Sisyphus/srpms/${1}" | grep -E 'ALT Linux repositories|ALT repositories' -A150 | grep 'SRPMs in branches' -A150 | \
	grep -v 'hide window' | grep -i 'Source RPM:' -B150 | sed -e "s/   //g" #| tr -d '[]'
	#| grep -E '\[*\]' | awk -F ']' '{print $NF}'
}

case "$1" in
	'alt' ) distro='alt'; pi_alt "$2" ;;
	* ) echo 'Unsupported distribution. Syntax: wr distro package_name, e.g.: wr alt opam' ;;
esac

