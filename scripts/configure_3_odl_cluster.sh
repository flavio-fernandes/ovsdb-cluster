#!/bin/bash

## set -o errexit
## set -o nounset
set -o pipefail

# This script will attempt to configure the 3 running odl containers
# to have the cluster (akka) configured. It will do so by invoking
# /root/scripts/configure-node.sh that has been pre-loaded in the
# docker image during build time.

ROOT=$(dirname "${BASH_SOURCE}")/..

cd "${ROOT}"
source ./env.sh

#--

ODL1_NAME="ovsdb-cluster-1"
ODL1_IP="${ODL_IP_BASE}.$((1 + OLD_IP_OFFSET))"

ODL2_NAME="ovsdb-cluster-2"
ODL2_IP="${ODL_IP_BASE}.$((2 + OLD_IP_OFFSET))"

ODL3_NAME="ovsdb-cluster-3"
ODL3_IP="${ODL_IP_BASE}.$((3 + OLD_IP_OFFSET))"

function invoke_cofigure_node {
    ODL_NAME=$1 ; shift
    ODL_INDEX=$1 ; shift
    ODL_IP1=$1 ; shift
    ODL_IP2=$1 ; shift
    ODL_IP3=$1 ; shift

    cmd="sudo docker exec ${ODL_NAME}"
    cmd+=" /root/scripts/configure-node.sh member-${ODL_INDEX} ${ODL_IP1} ${ODL_IP2} ${ODL_IP3}"
    cmd+=' 2>&1'
    echo "$cmd" ; rval=$(eval $cmd) ; rc=$?
    if [ $rc -ne 0 ]; then
	echo "Error: $rval -- rc=$rc" ; exit $rc
    fi
}

invoke_cofigure_node $ODL1_NAME 1 $ODL1_IP $ODL2_IP $ODL3_IP
invoke_cofigure_node $ODL2_NAME 2 $ODL2_IP $ODL3_IP $ODL1_IP
invoke_cofigure_node $ODL3_NAME 3 $ODL3_IP $ODL1_IP $ODL2_IP

echo ok
