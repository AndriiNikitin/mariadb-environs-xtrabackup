########################################################################
# Bug #1049291: innobackupex --copy-back fails with an empty
#               innodb-data-home-dir
########################################################################

MYSQLD_EXTRA_MY_CNF_OPTS="
innodb_data_home_dir=
"

start_server

innobackupex --no-timestamp $topdir/backup

stop_server

[ ! -z "$MYSQLD_DATADIR" ] && rm -rf $MYSQLD_DATADIR/*

innobackupex --apply-log $topdir/backup

innobackupex --copy-back $topdir/backup

test -f $MYSQLD_DATADIR/ibdata1

[ ! -z "$MYSQLD_DATADIR" ] && rm -rf $MYSQLD_DATADIR
