# the number of opendaylight containers
export ODLS=3

# the prefix ip address to be assigned to the container's eth1
export ODL_IP_BASE="192.168.50"

# the suffix ip address to be assigned to the container's eth1,
# minus the ODL_INDEX. So, for first container, the IP will be
# ${ODL_IP_BASE}.$((1 + OLD_IP_OFFSET))
export OLD_IP_OFFSET=10

# helper functions
function odl_shell { sudo docker exec -it ovsdb-cluster-${1} /bin/bash; }
function odl1 { odl_shell 1; }
function odl2 { odl_shell 2; }
function odl3 { odl_shell 3; }
