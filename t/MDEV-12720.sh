. inc/common.sh

if [ -z "$INNODB_VERSION" ]; then
    skip_test "Requires InnoDB plugin or XtraDB"
fi

start_server

run_cmd $MYSQL $MYSQL_ARGS -e \
    "create table test.a(i int primary key auto_increment, s varchar(255) ) ENGINE=InnoDB ROW_FORMAT=compressed" 

run_cmd $MYSQL $MYSQL_ARGS -e \
    "insert into test.a(i) select null"

run_cmd $MYSQL $MYSQL_ARGS -e \
    "insert into test.a select null, uuid() from test.a a, test.a b, test.a c"
run_cmd $MYSQL $MYSQL_ARGS -e \
    "insert into test.a select null, uuid() from test.a a, test.a b, test.a c"
run_cmd $MYSQL $MYSQL_ARGS -e \
    "insert into test.a select null, uuid() from test.a a, test.a b, test.a c"

run_cmd $MYSQL $MYSQL_ARGS -e \
    "select count(*) from test.a"

# sleep 2

mkdir -p $topdir/backup
innobackupex --no-timestamp $topdir/backup
stop_server

rm -rf $mysql_datadir

vlog "Applying log"

innobackupex --apply-log $topdir/backup

vlog "Restoring MySQL datadir"
mkdir -p $mysql_datadir
innobackupex --copy-back $topdir/backup

start_server

