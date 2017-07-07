#!/bin/bash

set -e
[ ! -z "$1" ] || { >&2 echo "Expected environ id for backup"; exit 1; }

cnf=$(ls -A "$1"*/my.cnf 2>/dev/null| head -n1 )

[ ! -z "$cnf" ] || { >&2 echo "Cannot find my.cnf in $1*"; exit 1; }

targetdir=${2}
[ -z "$targetdir" ] && targetdir=$(cd "$1"*/bkup 2>/dev/null && pwd )
[ -d "$targetdir" ] || { >&2 echo "Cannot detect backup target dir"; exit 1; }

__workdir/../_depot/x-tar/2.4.7/bin/xtrabackup --defaults-file=$cnf --backup --target-dir=${targetdir}
__workdir/../_depot/x-tar/2.4.7/bin/xtrabackup --defaults-file=$cnf --prepare --target-dir=${targetdir}

