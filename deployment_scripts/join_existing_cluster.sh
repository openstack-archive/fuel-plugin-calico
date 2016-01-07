#!/bin/bash
# Copyright 2015 Metaswitch Networks

caller=$1
node_address=$2
initial_cluster=$3

CALLED_BY=/tmp/etcd_cfg_modifiers
touch ${CALLED_BY}
num_callers=$(wc -l < ${CALLED_BY})
if [[ $num_callers != 0 ]]; then
  # Someone else has already run this script - exit.
  exit
fi

echo ${caller} >> ${CALLED_BY}
sleep 1
num_callers=$(wc -l < ${CALLED_BY})
if [[ $num_callers > 1 ]]; then
  # Someone else is also trying to run this script, back off unless the caller wins an arbitrary
  # tiebreak of an alphabetical sort.
  callers=$(cat ${CALLED_BY} | sort)
  if [[ "$caller" != "${callers[0]}" ]]; then
    exit
  fi
fi

service etcd stop
rm -rf /var/lib/etcd/*
awk '/exec \/usr\/bin\/etcd/{while(getline && $0 != ""){}}1' /etc/init/etcd.conf > tmp
mv tmp /etc/init/etcd.conf
cat << EXEC_CMD >> /etc/init/etcd.conf
exec /usr/bin/etcd -name ${node_address}                                                            \\
                   -advertise-client-urls "http://${node_address}:2379,http://${node_address}:4001" \\
                   -listen-client-urls "http://0.0.0.0:2379,http://0.0.0.0:4001"                    \\
                   -listen-peer-urls "http://0.0.0.0:2380"                                          \\
                   -initial-advertise-peer-urls "http://${node_address}:2380"                       \\
                   -initial-cluster-token fuel-cluster-1                                            \\
                   -initial-cluster ${initial_cluster}                                              \\
                   -initial-cluster-state existing
EXEC_CMD
service etcd start

