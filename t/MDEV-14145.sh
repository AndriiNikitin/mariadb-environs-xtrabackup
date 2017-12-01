set -e
start_server

run_cmd $MYSQL $MYSQL_ARGS -e \
    "CREATE TABLE t1(c1 INT); ALTER TABLE t1 ENGINE=InnoDB; INSERT INTO t1 VALUES(1);" test

mkdir -p $topdir/backup
xtrabackup --backup --target-dir=$topdir/backup
xtrabackup --prepare --target-dir=$topdir/backup

stop_server

[ ! -z "$mysql_datadir" ] || exit 555

rm -rf $mysql_datadir

vlog "Applying log"

xtrabackup --prepare $topdir/backup

vlog "Restoring MySQL datadir"
mkdir -p $mysql_datadir
xtrabackup --copy-back $topdir/backup

start_server

run_cmd $MYSQL $MYSQL_ARGS -e "checksum table t1;" test

