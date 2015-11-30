#!/bin/bash
# Copyright 2015 Metaswitch Networks

this_node_address=$(python get_node_ip.py `hostname`)
controller_node_addresses=$(python get_node_ips_by_role.py controller)

for node_address in ${controller_node_addresses[@]}
do
  initial_cluster+="${node_address}=http://${node_address}:2380,"
done

initial_cluster=${initial_cluster::-1} # remove trailing comma

service etcd stop
rm -rf /var/lib/etcd/*
awk '/exec \/usr\/bin\/etcd/{while(getline && $0 != ""){}}1' /etc/init/etcd.conf > tmp
mv tmp /etc/init/etcd.conf
cat << EXEC_CMD >> /etc/init/etcd.conf
exec /usr/bin/etcd -name ${this_node_address}                                                                 \\
                   -advertise-client-urls "http://${this_node_address}:2379,http://${this_node_address}:4001" \\
                   -listen-client-urls "http://0.0.0.0:2379,http://0.0.0.0:4001"                              \\
                   -listen-peer-urls "http://0.0.0.0:2380"                                                    \\
                   -initial-advertise-peer-urls "http://${this_node_address}:2380"                            \\
                   -initial-cluster-token fuel-cluster-1                                                      \\
                   -initial-cluster ${initial_cluster}                                                        \\
                   -initial-cluster-state new

EXEC_CMD
service etcd start

retry_count=0
while [[ $retry_count < 5 ]]; do
  etcdctl cluster-health
  if [[ $? == 0 ]]; then
    break
  else
    ((retry_count++))
    service etcd restart
    sleep 2
  fi
done

