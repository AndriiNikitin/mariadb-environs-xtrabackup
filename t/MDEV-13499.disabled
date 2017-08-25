set -e
start_server

run_cmd $MYSQL $MYSQL_ARGS -e \
    "CREATE TABLE t1(c1 INT); INSERT INTO t1 VALUES(1);" test

stop_server

cp $mysql_datadir/test/t1.frm $mysql_datadir/test/t1_1.frm
cp $mysql_datadir/test/t1.ibd $mysql_datadir/test/t1_1.ibd

start_server

run_cmd $MYSQL $MYSQL_ARGS -e \
    "select * from test.t1_1; select * from test.t1" test

mkdir -p $topdir/backup
xtrabackup --backup --target-dir=$topdir/backup

