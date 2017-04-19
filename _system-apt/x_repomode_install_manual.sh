#!/bin/bash

# 2.3.7
declare -r ver=$1

# "manual", may be "manuale" for Enterprise repo
declare -r mode=$2

. common.sh

declare -r distcode=$(detect_distcode)

declare -r folder=$(_system/x_repomode_url_${mode}.sh $ver)
declare -r destination=_depot/x-system/$distcode/$ver$mode

declare -r pkglist="percona-xtrabackup percona-xtrabackup-test"

declare -r -a pkgarray=($pkglist)

wget -V > /dev/null || apt-get -y install wget
grep -qP . /etc/*release &>/dev/null || apt-get install libpcre3

mkdir -p $destination

download () {
  local -r package=$1
  local -r file1=${package}_${ver}-1.${distcode}_$(detect_amd64).deb
  local -r file2=${package}_${ver}-2.${distcode}_$(detect_amd64).deb
  if [[ ! -f $destination/$file1 ]] && [[ ! -f $destination/$file2 ]] ; then 
    wget -nv -nc $folder$file1 -P $destination || wget -nv -nc $folder$file2 -P $destination || { err=$? ; echo "Error ("$err") downloading file: "$folder$file2 1>&2 ; exit $err; }
  fi
}

for i in ${pkgarray[@]}
do
  download $i
done

# this will install only dependancies, excluding upgrades and mysql/mariadb packages
# need derty hack with perl regexp below to actually include perl dependencies which have mysql in it
apt-install-depends() {
      apt-get install -s $@ \
    | sed -n \
      -e "/^Inst $pkg /d" \
      -e 's/^Inst \([^ ]\+\) .*$/\1/p' \
    | grep -v xtrabackup \
    | grep -v updates \
    | xargs apt-get -y --no-install-recommends install
}

apt-install-depends ${pkglist[@]}

dpkg -i $destination/*.deb
