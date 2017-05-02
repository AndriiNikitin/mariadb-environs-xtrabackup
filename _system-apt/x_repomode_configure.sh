#!/bin/bash

. common.sh

wget -V > /dev/null || apt-get -y install wget

declare -r debname="percona-release_0.1-4.$(detect_distcode)_all.deb"

[[ -f "$debname" ]] && rm -- "$debname"

dest=_depot/x-system/$(detect_distcode)

mkdir -p $dest

wget -rc -nH --cut-dirs=1 -P$dest "https://repo.percona.com/apt/$debname"

dpkg -i $dest/$debname

