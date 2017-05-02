#!/bin/bash

. common.sh

[[ $1 =~ ([1-9][0-9]?\.[0-9])(.)?($) ]] && mode=repo${BASH_REMATCH[2]} && VER=${BASH_REMATCH[1]}
[[ $1 =~ ([1-9][0-9]?\.[0-9]\.[0-9][0-9]?)(.)? ]] && mode=manual${BASH_REMATCH[2]} && VER=${BASH_REMATCH[1]}

if [[ $mode =~ repo* ]] ; then
   MAJOR=$VER
else
   MAJOR=${VER%\.*}
fi

[ ! -z "$VER" ] || { echo "Expected XtraBackup version as first parameter, e.g. 2.3 or 2.4.5 ; got ($VER)";  exit 2; }

# remove old repos if exist
for SCRIPT in _system/x_repomode_clean*.sh
do
  $SCRIPT
done

if [ -f _system/x_repomode_configure_$mode.sh ] ; then
  _system/x_repomode_configure_$mode.sh $MAJOR
else
  _system/x_repomode_configure.sh $MAJOR
fi

if [ -f _system/x_repomode_install_${mode}.sh ] ; then
  _system/x_repomode_install_${mode}.sh $VER ${mode}
else
  _system/x_repomode_install_${mode%?}*.sh $VER ${mode}
fi

