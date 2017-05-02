#!/bin/bash

vers=$1

# 2.4 has different package name - fix with suffix
[[ $vers == 2.4* ]] && suff=-24

apt-get install -y percona-xtrabackup$suff
