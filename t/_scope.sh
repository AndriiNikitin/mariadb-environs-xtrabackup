
shopt -u nullglob
[ -z "$1" ] && exit

[ -z "$MYSQL_VERSION" ] && { echo Variable is not defined: MYSQL_VERSION 1>&2 ; exit 1; }

if ls ./$1*/config_load/configure_innodb_plugin.sh >/dev/null 2>&1 ; then
   [ -z "$INNODB_VERSION" ] && { echo Variable is not defined: INNODB_VERSION 1>&2 ; exit 1; }
else
   [ -z "$XTRADB_VERSION" ] && { echo Variable is not defined: XTRADB_VERSION 1>&2 ; exit 1; }
fi

which xtrabackup || [[ ! -z "${BASH_ALIASES[xtrabackup]}" ]]   || { echo alias "xtrabackup" must be defined to run this suite; exit 2; }
which innobackupex || [[ ! -z "${BASH_ALIASES[innobackupex]}" ]] || { echo alias "innobackupex" must be defined to run this suite; exit 2; }
which mysql || [[ ! -z "${BASH_ALIASES[mysql]}" ]]        || { echo alias "mysql" must be defined to run this suite; exit 2; }

[ ! -z ${MARIADB_VERSION} ] && echo Product=${MARIADB_VERSION}
echo Product=${MYSQL_VERSION}

v=$(xtrabackup -v 2>&1)
echo Product=${v#*\ }

OS=$(cat /etc/*release | grep PRETTY_NAME= | head -n 1)
echo OS=${OS#PRETTY_NAME=}


if ls ./$1*/configure_innodb_plugin.sh >/dev/null 2>&1 ; then
  if ls  ./$1*/config_load/configure_innodb_plugin.sh >/dev/null 2>&1 ; then
    echo configure_innodb_plugin.sh=1
  else
    echo configure_innodb_plugin.sh=0
  fi
fi

if [[ $(xtrabackup -v 2>&1) == *"MariaDB"* ]] ; then
  if ls ./$1*/configure_rest_encryption.sh &>/dev/null  ; then
    if ls ./$1*/config_load/configure_rest_encryption.sh &> /dev/null ; then
      echo configure_rest_encryption.sh=1
    else
      echo configure_rest_encryption.sh=0
    fi
  fi
else
  if ls ./$1*/config_load/configure_rest_encryption.sh &>/dev/null ; then
    echo Can use rest encryption only with MariaDB xtrabackup 1>&2 
    exit 3
  else
    echo configure_rest_encryption.sh=NA
  fi
fi

if ls ./$1*/configure_innodb_page_compression.sh &> /dev/null ; then
  if ls ./$1*/config_load/configure_innodb_page_compression.sh &>/dev/null ; then
    echo configure_innodb_page_compression.sh=1
  else
    echo configure_innodb_page_compression.sh=0
  fi
fi

ls ./$1*/config_load/configure_extra.cnf >& /dev/null && cat ./$1*/config_load/configure_extra.cnf
