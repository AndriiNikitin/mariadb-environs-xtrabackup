#!/bin/bash
set -e

. common.sh

# extract worker prefix, e.g. m12
wwid=${1%%-*}
# extract number, e.g. 12
wid=${wwid:1:100}

workdir=$(find . -maxdepth 1 -type d -name "$wwid*" | head -1)

# if folder exists - it must be empty 
if [[ -d $workdir ]]; then
  [[ $(ls -A $workdir) ]] && ((>&2 echo "Non-empty $workdir aready exists, expected unassigned worker id") ; exit 1)

  [[ $workdir =~ ($wwid-)([1-9]?)(\.)([0-9])(\.)([1-9]?) ]] || ((>&2 echo "Couldn't parse format of $workdir, expected $wwid-version") ; exit 1)
  version=${BASH_REMATCH[2]}.${BASH_REMATCH[4]}.${BASH_REMATCH[6]}
fi

workdir=$(pwd)/$wwid-$version
[[ -d $workdir ]] || mkdir $workdir


for filename in _plugin/*/x-version/* ; do
  m4 -D__workdir=$workdir -D__version=$version $filename > $workdir/$(basename $filename)
done

detect_windows || for filename in _plugin/*/x-version/*.sh ; do
  chmod +x $workdir/$(basename $filename)
done
