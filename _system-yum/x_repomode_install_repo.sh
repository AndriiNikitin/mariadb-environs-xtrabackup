#!/bin/bash

. common.sh

# try to install libev and enable epel if needed (https://bugs.launchpad.net/percona-xtrabackup/+bug/1526636) 
if ! yum install -y libev && ! yum install -y epel-release ; then
  yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(detect_distver).noarch.rpm \
  && yum install -y libev
fi

ver=$1

[[ $ver == 2.4* ]] && suff=-24

yum install -y percona-xtrabackup${suff}
