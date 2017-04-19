#!/bin/bash

. common.sh

yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm

# try to install libev and enable epel if needed (https://bugs.launchpad.net/percona-xtrabackup/+bug/1526636) 
if ! yum install -y libev && ! yum install -y epel-release ; then
  yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(detect_distver).noarch.rpm \
  && yum install -y libev
fi
