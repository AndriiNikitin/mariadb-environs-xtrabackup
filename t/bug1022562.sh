. inc/common.sh

mysqld_additional_args="--innodb_file_per_table"
  
start_server ${mysqld_additional_args}

load_dbase_schema incremental_sample

# Full backup

# Full backup folder
rm -rf $topdir/full
mkdir -p $topdir/full
# Incremental data
rm -rf $topdir/delta
mkdir -p $topdir/delta

vlog "Starting backup"

xtrabackup --datadir=$mysql_datadir --backup --target-dir=$topdir/full \
    $mysqld_additional_args

vlog "Full backup done"

# Changing data in sakila

vlog "Making changes to database"

${MYSQL} ${MYSQL_ARGS} -e "CREATE TABLE t2 (a INT(11) DEFAULT NULL, \
 number INT(11) DEFAULT NULL) ENGINE=INNODB" incremental_sample
${MYSQL} ${MYSQL_ARGS} -e "INSERT INTO t2 VALUES (1, 1)" incremental_sample
  
vlog "Changes done"

# Saving the checksum of original table
checksum_t2_a=`checksum_table incremental_sample t2`

vlog "Table 't2' checksum is $checksum_t2_a"

vlog "Making incremental backup"

# Incremental backup
xtrabackup --datadir=$mysql_datadir --backup \
    --target-dir=$topdir/delta --incremental-basedir=$topdir/full \
    $mysqld_additional_args

vlog "Incremental backup done"
vlog "Preparing backup"

# Prepare backup
xtrabackup --datadir=$mysql_datadir --prepare --apply-log-only \
    --target-dir=$topdir/full $mysqld_additional_args
vlog "Log applied to backup"

xtrabackup --datadir=$mysql_datadir --prepare --apply-log-only \
    --target-dir=$topdir/full --incremental-dir=$topdir/delta \
    $mysqld_additional_args
vlog "Delta applied to backup"

xtrabackup --datadir=$mysql_datadir --prepare --target-dir=$topdir/full \
    $mysqld_additional_args
vlog "Data prepared for restore"

# removing rows
${MYSQL} ${MYSQL_ARGS} -e "delete from t2;" incremental_sample
vlog "Table cleared"

# Restore backup

stop_server

vlog Clean up old logs

[ -z "$mysql_datadir" ] || rm -rf $mysql_datadir/ib_log*

vlog "Copying files"

cd $topdir/full/
cp -r * $mysql_datadir
cd -
[ -s "$mysql_datadir/ib_logfile0" ] || rm "$mysql_datadir/ib_logfile0"

vlog "Data restored"

start_server ${mysqld_additional_args}

vlog "Checking checksums"
checksum_t2_b=`checksum_table incremental_sample t2`

if [ "$checksum_t2_a" != "$checksum_t2_b"  ]
then 
    vlog "Checksums of table 't2' are not equal $checksum_t2_a <> $checksum_t2_b"
    exit -1
fi

vlog "Checksums are OK"

stop_server
