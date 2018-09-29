#!/bin/sh
# License: GPLv3
# Author: mikhailnov
# This is a quick & dirty script to help sycnronize local packages and downgrade them to the versions from the main ALT's repository
# e.g. to rollback partial uncessfull upgrade from p8 to Sisyphus

dir0="$(pwd)"
date="$(date +%s)"
rm -fv /var/cache/apt/archives/* 2>/dev/null
diff_pkg_list="/tmp/diff_pkg_${date}.list"
tmp_dir="/tmp/downloaded_packages_${date}"
touch "$diff_pkg_list" || ( echo "Error creating temp file {$diff_pkg_list}"; exit 1 )
system_arch="$(apt-config dump | grep 'APT::Architecture' | tr -d '"";' | awk '{print $NF}')"

check_root(){
	if [ "$(id -u)" != "0" ]; then
		echo "Скрипт нужно запустить от root!"
		echo "Run this script as root!"
		exit 1
	fi
}

set_repo_var(){
	uniq_branch_list="$(apt-repo | tr ' ' '\n' | grep 'branch/' | awk -F '/' '{print $1}' | sort | uniq)"
	uniq_branch_number="$(echo "$uniq_branch_list" | wc -l)"
	if [ "$uniq_branch_number" -gt 1 ]
		then
			echo "Check your repository list (apt-repo). You have more than 1 branch active. We cannot understand which one is the main. Exiting."
			return 1
		else
			branch="$uniq_branch_list"
			return 0
	fi
}

make_list_of_packages(){
	for pkg in $(rpm -qa --qf "%{NAME}\n")
	#for pkg in libmount
	do
		echo "Package: ${pkg}"
		apt_cache_policy="$(env LANG=c apt-cache policy "$pkg")"
		apt_show="$(env LANG=c apt-cache show "$pkg")"
		installed_version="$(echo "$apt_cache_policy" | grep '\*\*\*' | awk '{print $2}')"
		#target_version="$(echo "$apt_cache_policy" | grep 'Candidate:' | awk -F 'Candidate: ' '{print $NF}')"
		target_version="$(echo "$apt_cache_policy" | grep "$branch" -B1 | head -n 1 | sed -e 's/\*\*\* //g' | awk '{print $1}')"
		pkg_arch="$(echo "$apt_show" | grep '^Architecture' | awk -F 'Architecture: ' '{print $NF}' | sort | uniq | head -n 1)"
		echo "Installed version: ${installed_version}, Target version: ${target_version}"
		if [ ! "$installed_version" = "$target_version" ]; then
			diff_pkg="${diff_pkg} ${pkg}"
			echo "Versions of ${pkg} differ"
			echo "${pkg};;${target_version};;${pkg_arch}" >> "${diff_pkg_list}"
		fi
		#echo "diff_pkg: ${diff_pkg}"
	done
}

download_packages(){
	mkdir -p "$tmp_dir" || ( echo "Cannot create temporary directory ${tmp_dir}, cannot continue!"; exit 1 )
	cd "$tmp_dir"
		
	while read -r line
	do
		pkg_name="$(echo "$line" | awk -F ';;' '{print $1}')"
		pkg_version="$(echo "$line" | awk -F ';;' '{print $2}')"
		pkg_arch="$(echo "$line" | awk -F ';;' '{print $3}')"
		#http://ftp.altlinux.org/pub/distributions/ALTLinux/p8/branch/files/x86_64/RPMS/lynx-2.8.6-alt9.rel.2.2.x86_64.rpm
		wget "http://ftp.altlinux.org/pub/distributions/ALTLinux/${branch}/branch/files/${pkg_arch}/RPMS/${pkg_name}-${pkg_version}.${pkg_arch}.rpm"
	done < "${diff_pkg_list}"
}

install_downloaded_packages(){
	echo "Temporary directory with downloaded packages is: ${tmp_dir}"
	set -x
	cd "$tmp_dir"
	apt-get install ./*.rpm || rpm -i --nodeps --force ./*.rpm
	set +x
	apt-get -f install
}

remove_pkg_duplicates(){
	duplicates_list="$(rpm -qa --qf "%{NAME}\n" | sort | uniq -c | grep -v ' 1 ' | awk '{print $NF}')"
	for i in $duplicates_list
	do
		for rpm in $(rpm -qa --qf "%{NAME},%{VERSION},%{RELEASE}\n" | grep "^${i}," | sort -t ',' -nk2 | sort -t ',' -nk3 | tail -n +2 | sed -e 's/,/-/g')
		do
			set -x
			rpm -e --justdb --nodeps "$rpm"
			set +x
		done
	done
}

check_root
set_repo_var || exit 1
make_list_of_packages
download_packages
install_downloaded_packages
