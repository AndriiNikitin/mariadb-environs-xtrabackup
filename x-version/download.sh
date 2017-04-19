#!/bin/bash

# example url  https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.4/binary/tarball/percona-xtrabackup-2.4.4-Linux-x86_64.tar.gz 

FILE=https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-__version/binary/tarball/percona-xtrabackup-__version-Linux-x86_64.tar.gz

mkdir -p __workdir/../_depot/x-tar/__version

cd __workdir/../_depot/x-tar/__version
[[ -f $(basename $FILE) ]] || wget -nc $FILE && tar -zxf $(basename $FILE) --strip 1
cd -


