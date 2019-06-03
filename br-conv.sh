#!/bin/sh
# Convert BuildRequires from libxxx-devel to pkgconfig(xxx)
# Authors: abondrov, mikhailnov

if [ -z "$1" ]; then
	echo "Empty input. Provide a path to spec file."
	exit 1
fi
if [ ! -f "$1" ]; then
	echo "File $1 not found"
	exit 1
fi

grep -E "^BuildRequires:|^BuildSuggests:" "$1" | grep '\-devel' | awk '{print $2}' | xargs urpmq --whatprovides --provides | grep 'pkgconfig(' | sort | uniq
