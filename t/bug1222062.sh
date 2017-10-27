########################################################################
# Bug #1222062: add option --close-files
########################################################################

start_server

mkdir $topdir/backup

innobackupex --close-files $topdir/backup

grep "backup: warning: close-files specified" $OUTFILE
