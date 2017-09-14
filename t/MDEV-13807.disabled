. inc/common.sh

function start_uncomitted_transaction()
{
    run_cmd $MYSQL $MYSQL_ARGS test <<EOF
START TRANSACTION;
insert into t select 1;
SELECT SLEEP(10000);
EOF
}

start_server

run_cmd $MYSQL $MYSQL_ARGS -e \
    "create table test.t select 1"

start_uncomitted_transaction &
job_master=$!

sleep 1

xtrabackup --backup --target-dir=$topdir/backup


xtrabackup --prepare --apply-log-only --target-dir=$topdir/backup 2>&1 | tee $topdir/applyonly.log
if grep -q 'Rollback of non-prepared transactions completed' $topdir/applyonly.log ; then
  echo FAIL Rollback was performed
  res=1
else
  echo PASS It looks no rollback was performed
  res=0
fi

kill -SIGKILL $job_master
stop_server

( exit $res )
