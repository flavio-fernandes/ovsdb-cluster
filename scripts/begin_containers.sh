#!/bin/bash

## set -o errexit
## set -o nounset
set -o pipefail

# This script will attempt to create the docker containers where
# opendaylight controller will run from

SCRIPT_DIR=$(dirname "${BASH_SOURCE}")
ROOT=$(dirname "${BASH_SOURCE}")/..

##export FAKE_PIPEWORK=yes
##export MOUNT_HOST_DIR=yes

# the location of pipework. If you don't have it there, grab it
# by using download_pipework.sh or update variable below.
PIPEWORK="${SCRIPT_DIR}/pipework"

cd "${ROOT}"
source ./env.sh

#--

function connect_container {
    ODL_NAME=$1 ; shift
    ODL_IP=$1 ; shift
    BRIDGE=br1

    echo "connect_container $ODL_NAME ip $ODL_IP"

    cmd="sudo ${PIPEWORK} $BRIDGE -i eth1 $ODL_NAME ${ODL_IP}/24"
    cmd+=' 2>&1'
    echo "$cmd" ; rval=$(eval $cmd) ; rc=$?
    if [ $rc -eq 1 ]; then
	grep_rc=$(echo "$rval" | grep -i ' exists and is up')
	if [ -z "$grep_rc" ]; then
            echo "Error: $rc  $rval" ; exit $rc
	fi
    elif [ $rc -ne 0 ]; then
	echo "Error: $cid -- rc=$rc" ; exit $rc
    fi
}

#--

if [ "$FAKE_PIPEWORK" != "yes" ] && [ ! -x ${PIPEWORK} ]; then 
    echo "Error: check your pipes -- ${PIPEWORK}"
    echo "Maybe you forgot to run download_pipework.sh ?"
    exit 1 
fi

for ODL_INDEX in $(seq $ODLS); do
    ODL_IP="${ODL_IP_BASE}.$((ODL_INDEX + OLD_IP_OFFSET))"
    ODL_NAME="ovsdb-cluster-${ODL_INDEX}"
    echo "ODL index ${ODL_INDEX} has ip address ${ODL_IP} and name ${ODL_NAME}"

    cmd="sudo docker run -itd --hostname=${ODL_NAME} --name=${ODL_NAME}"
    cmd+=" -v ~/.m2:/root/.m2:ro"
    [ "$MOUNT_HOST_DIR" == "yes" ] && cmd+=" -v ${PWD}:/root/mnt"
    cmd+=" ovsdb-cluster"
    cmd+=' 2>&1'
    echo "$cmd" ; cid=$(eval $cmd) ; rc=$?
    if [ $rc -eq 1 ]; then
       cmd="sudo docker inspect --format '{{.State.Running}}' ${ODL_NAME}"
       cid_running=$(eval $cmd)
       if [ "$cid_running" != "true" ]; then
          echo "Error: $cid" ; exit $rc
       else
          echo "${ODL_NAME} is already running, continuing..."
       fi
    elif [ $rc -ne 0 ]; then
        echo "Error: $cid -- rc=$rc" ; exit $rc
    fi

    # use pipework to add eth1 to container. We leave eth0 alone so it
    # is only used as mgmt and default gateway for potential things that
    # may need container to reach public networks; like yum install
    [ "$FAKE_PIPEWORK" == "yes" ] || connect_container ${ODL_NAME} ${ODL_IP}

done

echo ok
