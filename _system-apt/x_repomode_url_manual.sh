#!/bin/bash

ver=$1

. common.sh

echo https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-$ver/binary/debian/$(detect_distcode)/$(detect_x86)/
