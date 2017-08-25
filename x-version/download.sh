#!/bin/bash

# example url  https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.4/binary/tarball/percona-xtrabackup-2.4.4-Linux-x86_64.tar.gz 

file=https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-__version/binary/tarball/percona-xtrabackup-__version-Linux-x86_64.tar.gz

mkdir -p __workdir/../_depot/x-tar/__version

(
cd __workdir/../_depot/x-tar/__version

function cleanup {
  [ -z "$wgetpid" ] || kill "$wgetpid" 2>/dev/null
}

trap cleanup INT TERM

if [ ! -f "$(basename $file)"  ] ; then
  echo downloading "$file"
  wget -q -np -nc $file &
  wgetpid=$!
  while kill -0 $wgetpid 2>/dev/null ; do
    sleep 10
    echo -n .
  done
  wait $wgetpid
  res=$?
  wgetpid=""
  if [ "$res" -ne 0 ] ; then
    >&2 echo "failed to download '$file' ($res)"
    exit $res 
  fi
fi

if [ -f "$(basename $file)" ] ; then
  if [ ! -x bin/mysqld ] ; then
    tar -zxf "$(basename $file)" --strip 1
  fi
fi
)
:

