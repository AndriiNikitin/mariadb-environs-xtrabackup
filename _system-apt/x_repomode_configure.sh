#!/bin/bash

. common.sh

wget -V > /dev/null || apt-get -y install wget

declare -r debname="percona-release_0.1-4.$(detect_distcode)_all.deb"

[[ -f "$debname" ]] && rm -- "$debname"

# todo move to _depot ?
wget -rc "https://repo.percona.com/apt/$debname"

dpkg -i $debname
