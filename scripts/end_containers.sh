#!/bin/bash

## set -o errexit
## set -o nounset
set -o pipefail

# This script will attempt to remove the docker containers where
# opendaylight controller will run from

SCRIPT_DIR=$(dirname "${BASH_SOURCE}")
ROOT=$(dirname "${BASH_SOURCE}")/..

cd "${ROOT}"
source ./env.sh

#--

for ODL_INDEX in $(seq $ODLS); do
    ODL_NAME="ovsdb-cluster-${ODL_INDEX}"

    cmd="sudo docker kill ${ODL_NAME}"
    cmd+=' 2>&1'
    echo "$cmd" ; rval=$(eval $cmd) ; rc=$?

    cmd="sudo docker rm ${ODL_NAME}"
    cmd+=' 2>&1'
    echo "$cmd" ; rval=$(eval $cmd) ; rc=$?
    if [ $rc -eq 1 ]; then
	grep_rc=$(echo "$rval" | grep -i 'no such id')
	if [ -z "$grep_rc" ]; then
            echo "Error: $rc  $rval" ; ## exit $rc
	fi
    elif [ $rc -ne 0 ]; then
	echo "Error: $rval -- rc=$rc" ; ## exit $rc
    fi
    
done

# last but not least, remove any veth interfaces that
# became orphan
cmd="scripts/remove_stale_veths.sh"
## cmd+=' all'
cmd+=' 2>&1'
echo "$cmd" ; rval=$(eval $cmd) ; rc=$?
echo $rval
exit $rc
