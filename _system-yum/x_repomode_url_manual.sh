#!/bin/bash

ver=$1

. common.sh

echo https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-$ver/binary/redhat/$(detect_distver)/$(detect_x86)/
