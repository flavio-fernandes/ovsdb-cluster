#!/bin/bash
# original version of this script comes from the blog page:
# http://vishnoianil.github.io/2015/09/ovsdb-clustering-development-environment-setup/
# All credits and kudos belong to my friend: Anil Vishnoi

export AKKA_CONF_PATH="/root/assembly/configuration/initial/akka.conf"

if [ "$#" -ne 4 ];then
        echo "\n$0 <local-node-role-name> <local-node-ip> <remove-node-1-ip> <remove-node-2-ip>\n"
        echo "\n	<local-node-role-name>            Please pick your role from the list [member-1, member-2, member-3] and don't use same for more then one node"
        echo "\n	<local-node-ip>                   IP address of the local node"
        echo "\n	<remote-node-1-ip>                IP address of the first remote node"
        echo "\n	<remove-node-2-ip>                IP address of the second remote node\n"
	echo "\n e.g $0 member-1 10.0.0.1 10.0.0.2 10.0.0.3\n"
        exit 1
fi

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function findDuplicate()
{
	echo $@ 
	local number_of_occurrences=1;
	number_of_occurrences=$(grep -o "$1" <<< "$@" | wc -l)
	return $number_of_occurrences
}

LOCAL_NODE_NAME=$1
if [ "$LOCAL_NODE_NAME" != "member-1" ] && [ "$LOCAL_NODE_NAME" != "member-2" ] && [ "$LOCAL_NODE_NAME" != "member-3" ]
then echo "ERROR : Please use member names from [member-1, member-2, member-3]. Just picking these roles to avoid some addition configurations in configuration file."
exit 1
fi

if valid_ip $2;then LOCAL_NODE_IP=$2; else echo "ERROR : Please provide valid local node ip address"; exit 1; fi
entries=$( grep -o "$LOCAL_NODE_IP" <<< "$@" | wc -l )
if [ "$entries" -gt "1" ]; then echo "ERROR : One of the remote node also has the same ip address [$LOCAL_NODE_IP]. Please fix it"; exit 1; fi

if valid_ip $3;then REMOTE_NODE_1_IP=$3; else echo "ERROR : Please provide valid remote node 1 ip address"; exit 1; fi
entries=$( grep -o "$REMOTE_NODE_1_IP" <<< "$@" | wc -l )
if [ "$entries" -gt "1" ]; then echo "ERROR : One of the other node also has the same ip address [$REMOTE_NODE_1_IP]. Please fix it"; exit 1; fi

if valid_ip $4;then REMOTE_NODE_2_IP=$4; else echo "ERROR : Please provide valid remote node 2 ip address"; exit 1; fi
entries=$( grep -o "$REMOTE_NODE_2_IP" <<< "$@" | wc -l )
if [ "$entries" -gt "1" ]; then echo "ERROR : One of the other node also has the same ip address [$REMOTE_NODE_1_IP]. Please fix it"; exit 1; fi

sed -i "s/hostname =.*/hostname = \"$LOCAL_NODE_IP\"/g" $AKKA_CONF_PATH

sed -i "s/seed-nodes =.*/seed-nodes = [\"akka.tcp:\/\/opendaylight-cluster-data@$LOCAL_NODE_IP:2550\",\"akka.tcp:\/\/opendaylight-cluster-data@$REMOTE_NODE_1_IP:2550\",\"akka.tcp:\/\/opendaylight-cluster-data@$REMOTE_NODE_2_IP:2550\"]/g" $AKKA_CONF_PATH

sed -i "s/member-.*/$LOCAL_NODE_NAME\"/g" $AKKA_CONF_PATH
