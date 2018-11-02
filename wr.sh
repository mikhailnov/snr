#!/bin/sh
# wr - which repo

pi_alt(){
	lynx -dump "https://packages.altlinux.org/en/Sisyphus/srpms/${1}" | grep 'ALT Linux repositories' -A150 | grep 'Source RPM:' -B150 | grep -E '\[*\]' | awk -F ']' '{print $NF}'
}

case "$1" in
	'alt' ) distro='alt'; pi_alt "$2" ;;
	* ) echo 'Unsupported distribution. Syntax: wr distro package_name, e.g.: wr alt opam' ;;
esac

