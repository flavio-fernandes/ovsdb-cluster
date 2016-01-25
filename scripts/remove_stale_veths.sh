#!/bin/bash

set -o errexit
set -o pipefail

# This script will remove stale veth* ports from OVS $BRIDGE
BRIDGE=br1

if [ "$1" = "all" ]; then
    IFs=$(sudo ovs-vsctl show | grep -oP "(?<=[\s\"])veth[^[\s\"]*" | sort -u)
else
    IFs=$(sudo ovs-vsctl show | grep "could not open" | grep -oP "(?<=\s)veth[^\s]*")
fi

for x in ${IFs} ; do echo $x ; sudo ovs-vsctl del-port $BRIDGE $x ; done

