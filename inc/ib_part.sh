

function check_partitioning()
{
    $MYSQL $MYSQL_ARGS -Ns -e "SHOW PLUGINS" 2> /dev/null |
      egrep -q "^partition"
}

function require_partitioning()
{
	if ! check_partitioning
	then
	    echo "Requires support for partitioning." > $SKIPPED_REASON
	    exit $SKIPPED_EXIT_CODE
	fi
}

function ib_part_schema()
{
	topdir=$1
	engine=$2

	cat <<EOF
CREATE TABLE test (
  a int(11) DEFAULT NULL
) ENGINE=$engine DEFAULT CHARSET=latin1 # PAGE_COMPRESSED=1
PARTITION BY RANGE (a)
(PARTITION p0 VALUES LESS THAN (100) ENGINE = $engine,
 PARTITION P1 VALUES LESS THAN (200) ENGINE = $engine,
 PARTITION p2 VALUES LESS THAN (300)
   DATA DIRECTORY = '$topdir/ext'
   ENGINE = $engine,
 PARTITION p3 VALUES LESS THAN (400)
   DATA DIRECTORY = '$topdir/ext'
   ENGINE = $engine,
 PARTITION p4 VALUES LESS THAN MAXVALUE ENGINE = $engine);
EOF
}

function ib_part_data()
{
	echo 'INSERT INTO test VALUES (1), (101), (201), (301), (401);';
}

function ib_part_init()
{
	topdir=$1
	engine=$2

	if [ -d $topdir/ext ] ; then
		rm -rf $topdir/ext
	fi
	mkdir -p $topdir/ext

	ib_part_schema $topdir $engine | run_cmd $MYSQL $MYSQL_ARGS test
	ib_part_data $topdir $engine | run_cmd $MYSQL $MYSQL_ARGS test
}

function ib_part_add_mandatory_tables()
{
	local mysql_datadir=$1
	local tables_file=$2
	for table in $mysql_datadir/mysql/*.frm
	do
	        echo mysql.`basename ${table%.*}` >> $tables_file
	done
	for table in $mysql_datadir/performance_schema/*.frm
	do
	    echo performance_schema.`basename ${table%.*}` >> $tables_file
	done
}

function ib_part_restore()
{
	topdir=$1
	mysql_datadir=$2

	# Remove database
	rm -rf $mysql_datadir/*
	rm -rf $topdir/ext/*
	vlog "Original database removed"

	# Restore database from backup
	cp -rv $topdir/backup/* $mysql_datadir
	[ -s "$mysql_datadir/ib_logfile0" ] || rm "$mysql_datadir/ib_logfile0"
      
	vlog "database restored from backup"

}

function ib_part_assert_checksum()
{
	checksum_a=$1

	vlog "Checking checksums"
	checksum_b=`checksum_table test test`

	vlog "Checksums are $checksum_a and $checksum_b"

	if [ "$checksum_a" != "$checksum_b" ]
	then 
		vlog "Checksums are not equal"
		exit -1
	fi

	vlog "Checksums are OK"

}
