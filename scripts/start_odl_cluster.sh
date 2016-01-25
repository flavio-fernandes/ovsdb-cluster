#!/bin/bash

## set -o errexit
## set -o nounset
set -o pipefail

# This script will attempt to start ODL on all containers.

ROOT=$(dirname "${BASH_SOURCE}")/..

# export SKIP_START_CHECK=yes

export ODL_USERNAME=admin
export ODL_PASSWORD=admin
export ODL_RESTCONF_PORT=8181
export ODL_BOOT_WAIT_URL='restconf/operational/network-topology:network-topology/topology/netvirt:1'
export ODL_BOOT_WAIT=600
export ODL_RETRY_SLEEP_INTERVAL=3

cd "${ROOT}"
source ./env.sh

#--

# Test with a finite retry loop.
#
function test_with_retry {
    local testcmd=$1
    local failmsg=$2
    local until=${3:-600}
    local sleep=${4:-2.5}

    if ! timeout $until sh -c "while ! $testcmd; do echo -n '.'; sleep $sleep; done"; then
        echo "$failmsg"
	exit 1
    fi
}

#--

for ODL_INDEX in $(seq $ODLS); do
    ODL_IP="${ODL_IP_BASE}.$((ODL_INDEX + OLD_IP_OFFSET))"
    ODL_NAME="ovsdb-cluster-${ODL_INDEX}"

    # test basic connectivity
    cmd="ping -c 2 ${ODL_IP}"
    cmd+=' 2>&1'
    # echo "$cmd" ; 
    rval=$(eval $cmd) ; rc=$?
    if [ $rc -ne 0 ]; then
        echo "Error getting to ${ODL_NAME}: $cmd" ; echo "$rval -- rc=$rc" ; exit $rc
    fi

    # test if not already started
    cmd="sudo docker exec -i ${ODL_NAME}"
    cmd+=" bash -c 'cd assembly && bin/status'"
    cmd+=' 2>&1'
    echo "$cmd" ; rval=$(eval $cmd) ; rc=$?
    grep_rc=$(echo "$rval" | grep -i 'not running')
    if [ -z "$grep_rc" ]; then
        #echo "$rval"
        echo "${ODL_NAME} already has ODL running, skipping"
        continue
    fi

    # start odl
    cmd="sudo docker exec -i ${ODL_NAME}"
    cmd+=" bash -c 'cd assembly && bin/start'"
    cmd+=' 2>&1'
    echo "$cmd" ; rval=$(eval $cmd) ; rc=$?
    if [ $rc -ne 0 ]; then
        echo "Error: $rval -- rc=$rc" ; exit $rc
    fi
done

##--

if [ "${SKIP_START_CHECK}" != "yes" ]; then
    for ODL_INDEX in $(seq $ODLS); do
	ODL_IP="${ODL_IP_BASE}.$((ODL_INDEX + OLD_IP_OFFSET))"
	ODL_NAME="ovsdb-cluster-${ODL_INDEX}"

	# test netvirt connectivity
	echo -n "waiting for ${ODL_NAME} to become fully operational "

        # Probe ODL restconf for netvirt until it is operational
        testcmd="curl -o /dev/null --fail --silent --head -u \
              ${ODL_USERNAME}:${ODL_PASSWORD} http://${ODL_IP}:${ODL_RESTCONF_PORT}/${ODL_BOOT_WAIT_URL}"
        test_with_retry "$testcmd" "Opendaylight did not start after $ODL_BOOT_WAIT" \
              $ODL_BOOT_WAIT $ODL_RETRY_SLEEP_INTERVAL

        echo "... done"
    done
fi

echo ok
