. inc/common.sh

require_galera

ADDR=127.0.0.1

if [[ -n ${WSREP_DEBUG:-} ]];then 
    start_server --log-bin=`hostname`-bin --binlog-format=ROW \
                 --wsrep-provider=$LIBGALERA_PATH \
                 --wsrep_cluster_address=gcomm:// \
                 --wsrep-debug=1 --wsrep_provider_options="debug=1" \
                 --wsrep_node_address=$ADDR
else
    start_server --log-bin=`hostname`-bin --binlog-format=ROW \
                 --wsrep-provider=$LIBGALERA_PATH \
                 --wsrep_cluster_address=gcomm:// --wsrep_node_address=$ADDR
fi

backup_dir=$topdir/backup

innobackupex --no-timestamp --galera-info $backup_dir 

vlog "Backup created in directory $backup_dir"

# Test if backup locks are supported by the server and thus, whether
# xtrabackup_galera_info should be created on the backup or prepare stage
if has_backup_locks
then
    vlog "Preparing the backup to create xtrabackup_galera_info"
    innobackupex --apply-log $backup_dir
fi

test -f $backup_dir/xtrabackup_galera_info ||
  die "xtrabackup_galera_info was not created"

if [[ "`${MYSQL} ${MYSQL_ARGS} -Ns -e 'SHOW STATUS LIKE "wsrep_local_state_uuid"'|awk {'print $2'}`" == "`sed  -re 's/:.+$//' $backup_dir/xtrabackup_galera_info`" && "`${MYSQL} ${MYSQL_ARGS} -Ns -e 'SHOW STATUS LIKE "wsrep_last_committed"'|awk {'print $2'}`" == "`sed  -re 's/^.+://' $backup_dir/xtrabackup_galera_info`" ]]
then
	vlog "File is written correctly"
else
	vlog "File incorrect"
	exit 1
fi

stop_server
