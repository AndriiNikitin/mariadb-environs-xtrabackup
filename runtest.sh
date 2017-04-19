#!/bin/bash
. common.sh


export DEBUG=

shopt -s extglob

[ -z "$1" ] && exit 1

# since we change pwd - need to adjust $1
tname=$1

# unless it is absolute path
[[ "$tname" = /* ]] || tname=$(pwd)/$tname

cd _plugin/xtrabackup
workerid=${2:-0}
VARFOLDER="$ERN_VARDIR/__var${workerid}"

set +e

. inc/common.sh
# . subunit.sh

# trap cleanup_on_exit EXIT
# trap terminate SIGHUP SIGINT SIGQUIT SIGTERM

# Magic exit code to indicate a skipped test
export SKIPPED_EXIT_CODE=200

# Default server installation directory (-d option)
MYSQL_BASEDIR=${MYSQL_BASEDIR:-$PWD/server}

TEST_BASEDIR="$PWD"


function find_program()
{
    local VARNAME="$1"
    shift
    local PROGNAME="$1"
    shift

if [ ! -z "$(alias $PROGNAME 2>/dev/null)" ] ; then
  local f=${BASH_ALIASES[$PROGNAME]}
  # use only first word
  f=${f/%\ */}
  eval "$VARNAME=\"$f\""
  echo $VARNAME set to $f
  # xbstream used differently in the sripts, so should we treat it differently as well
  [ "$PROGNAME" != xbstream ] && unalias $PROGNAME
else        
    local DIRLIST="$*"
    local found=""

    for dir in $DIRLIST
    do
	if [ -d "$dir" -a -x "$dir/$PROGNAME" ]
	then
	    eval "$VARNAME=\"$dir/$PROGNAME\""
	    found="yes"
	    break
	fi
    done
    if [ -z "$found" ]
    then
	echo "Can't find $PROGNAME in $DIRLIST"
	exit -1
    fi
fi
}

########################################################################
# Explore environment and setup global variables
########################################################################
function set_vars()
{
    if gnutar --version > /dev/null 2>&1
    then
	TAR=gnutar
    elif gtar --version > /dev/null 2>&1
    then
	TAR=gtar
    else
	TAR=tar
    fi

    find_program MYSQL_INSTALL_DB mysql_install_db $MYSQL_BASEDIR/bin \
	$MYSQL_BASEDIR/scripts
    find_program MYSQLD mysqld $MYSQL_BASEDIR/bin/ $MYSQL_BASEDIR/libexec
    find_program MYSQL mysql $MYSQL_BASEDIR/bin
    find_program MYSQLADMIN mysqladmin $MYSQL_BASEDIR/bin
    find_program MYSQLDUMP mysqldump $MYSQL_BASEDIR/bin

    PATH="${MYSQL_BASEDIR}/bin:$PATH"

    if [ -z "${LD_LIBRARY_PATH:-}" ]; then
	LD_LIBRARY_PATH=$MYSQL_BASEDIR/lib/mysql
    else
	LD_LIBRARY_PATH=$MYSQL_BASEDIR/lib/mysql:$LD_LIBRARY_PATH
    fi
    DYLD_LIBRARY_PATH="$LD_LIBRARY_PATH"

    export TAR MYSQL_BASEDIR MYSQL MYSQLD MYSQLADMIN \
MYSQL_INSTALL_DB PATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH MYSQLDUMP
}


# Fix innodb51 test failures on Centos5-32 Jenkins slaves due to SELinux
# preventing shared symbol relocations in ha_innodb_plugin.so.0.0.0
function fix_selinux()
{
    if which lsb_release &>/dev/null && \
        lsb_release -d | grep CentOS &>/dev/null && \
        lsb_release -r | egrep '5.[0-9]' &>/dev/null && \
        which chcon &>/dev/null
    then
        chcon -t textrel_shlib_t $MYSQL_BASEDIR/lib/plugin/ha_innodb_plugin.so.0.0.0
    fi
}


function get_version_info()
{
    if [ -z "$(alias xtrabackup 2>/dev/null)" ] ; then 
      XB_BIN="xtrabackup"
    else
      local f=${BASH_ALIASES[xtrabackup]}
      # use only first word
      f=${f/%\ */} 
      XB_BIN=$f
      unalias xtrabackup
    fi

#    MYSQL_VERSION="5.6.21"
#    INNODB_VERSION="5.6.21"
#    XTRADB_VERSION=""

    [[ $MYSQL_VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] || \
        die "Cannot parse server version: '$MYSQL_VERSION'"
    MYSQL_VERSION_MAJOR=${BASH_REMATCH[1]}
    MYSQL_VERSION_MINOR=${BASH_REMATCH[2]}
    MYSQL_VERSION_PATCH=${BASH_REMATCH[3]}

    if [[ $XB_BIN == *"/"* ]] ; then
      XB_PATH=$(dirname $XB_BIN)
    else
      XB_PATH="`which $XB_BIN`"
    fi

    if [ -z "$XB_PATH" ]
    then
	vlog "Cannot find '$XB_BIN' in PATH"
	return 1
    fi
#    XB_BIN="$XB_PATH"

    # Set the correct binary for innobackupex
    if [ -z "$(alias innobackupex 2>/dev/null)" ] ; then
      IB_BIN="`which innobackupex`"
    else
      local f=${BASH_ALIASES[innobackupex]}
      # use only first word
#      f=${f/%\ */}
      IB_BIN=$f
      unalias innobackupex
    fi
    if [ -z "$IB_BIN" ]
    then
	vlog "Cannot find 'innobackupex' in PATH"
	return 1
    fi
    MYSQLD_EXTRA_ARGS=""
    WSREP_READY="0"
    LIBGALERA_PATH=""
    # need to set topdir here because some tests refer it before starting server
    topdir=$VARFOLDER
    IB_ARGS=""
    XB_ARGS=""
    MYSQLD_VARDIR=""
 
    export MYSQL_VERSION MYSQL_VERSION_COMMENT MYSQL_FLAVOR \
	INNODB_VERSION XTRADB_VERSION INNODB_FLAVOR \
	XB_BIN IB_BIN IB_ARGS XB_ARGS MYSQLD_EXTRA_ARGS \
        WSREP_READY LIBGALERA_PATH
}


########################################################################
# Return the number of seconds since the Epoch, UTC
########################################################################
function now()
{
    date '+%s'
}

export ROOT_PORT=$(( 3900 + $workerid ))

set_vars
 
if [ ! -d "$tname" ]
then
   tests="$tname"
else
   tests="$tname/*.sh"
fi

[ -z "$OUTFILE" ] && export OUTFILE="$PWD/setup"


# check if previous mysql instance exists and force kill it
echo attempting to clean previous mysqld instances
# echo $(ls "$VARFOLDER"/mysqld*.pid) 2>/dev/null
xargs -P4 -I {} bash -x -c 'kill -9 $(cat {}) || :'< <(ls "$VARFOLDER"/mysqld*.pid 2>/dev/null) || :

[ -z "$(ls $VARFOLDER/mysqld*.id 2>/dev/null)" ] || sleep 2
echo $(ls "$VARFOLDER"/mysqld*.pid) 2>/dev/null

rm -rf $VARFOLDER
mkdir $VARFOLDER || (>&2 echo "Couldn't create work directory ($VARFOLDER), exiting "; exit 2)

# get_version_info &> $VARFOLDER/prestart.log || (>&2 echo "get_version_info failed. See log in $VARFOLDER/prestart.log "; exit 2)

# echo "Running against $MYSQL_FLAVOR $MYSQL_VERSION ($INNODB_FLAVOR $INNODB_VERSION)" |  tee -a $OUTFILE
# echo "Using '`basename $XB_BIN`' as xtrabackup binary" | tee -a $OUTFILE

shopt -s expand_aliases

for t in $tests
do
   if [ ! -f "$t" ] ; then
     echo "Cannot find file ($t) (pwd=$(pwd))" 1>&2
     RES=1
   else
     export TEST_VAR_ROOT=$VARFOLDER
     export TMPDIR=$VARFOLDER/tmp
     export MYSQLTEST_VARDIR=$VARFOLDER
     mkdir -p $TMPDIR
     get_version_info &> $VARFOLDER/prestart.log || { >&2 echo "get_version_info failed. See log in $VARFOLDER/prestart.log "; exit 2; }
     echo STARTING TEST
     . $t
     RES=$?
     echo TEST FINISHED WITH $RES
   fi
done

# Wait for in-progress workers to finish
# reap_all_workers

# print_status_and_exit

echo cleaning mysqld instances
echo $(ls "$VARFOLDER"/mysqld*.pid) 2>/dev/null
xargs -P4 -I {} bash -x -c 'kill -9 $(cat {})'< <(ls "$VARFOLDER"/mysqld*.pid 2>/dev/null) || :

[ -z "$(ls $VARFOLDER/mysqld*.pid 2>/dev/null)" ] || sleep 2
(exit $RES)
