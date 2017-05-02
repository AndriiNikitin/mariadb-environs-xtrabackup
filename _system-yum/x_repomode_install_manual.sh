#!/bin/bash

# 2.3.7
declare -r ver=$1

# "manual", may be "manuale" for Enterprise repo
declare -r mode=$2

. common.sh

declare -r distcode=$(detect_distcode)

declare -r folder=$(_system/x_repomode_url_${mode}.sh $ver)
declare -r destination=_depot/x-system/$(detect_distnameN)/$ver$mode

# declare -r pkglist="percona-xtrabackup percona-xtrabackup-test"
declare -r pkglist="percona-xtrabackup"

declare -r -a pkgarray=($pkglist)

wget -V > /dev/null || yum -y install wget
# grep -qP . /etc/*release &>/dev/null || apt-get install libpcre3

mkdir -p $destination

download () {
  local -r package=$1
  local -r file1=${package}-${ver}-1.el$(detect_distver).$(detect_x86).rpm
  local -r file2=${package}-${ver}-2.el$(detect_distver).$(detect_x86).rpm
  if [[ ! -f $destination/$file1 ]] && [[ ! -f $destination/$file2 ]] ; then 
    wget -nv -nc $folder$file1 -P $destination || wget -nv -nc $folder$file2 -P $destination || { err=$? ; echo "Error ("$err") downloading file: "$folder$file2 1>&2 ; exit $err; }
  fi
}

[[ $ver == 2.4* ]] && suff=-24

for i in ${pkgarray[@]}
do
  download $i$suff
done

retry 5 yum -y localinstall $destination/*.rpm
