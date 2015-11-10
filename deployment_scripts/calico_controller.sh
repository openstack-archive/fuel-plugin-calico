#!/bin/bash
# Copyright 2015 Metaswitch Networks

export DEBIAN_FRONTEND=noninteractive

exec > /tmp/calico_controller.log 2>&1

set -x

echo "Hi, I'm a controller node!"

this_node_address=$(python get_node_ip.py `hostname`)

# Get APT key for binaries.projectcalico.org.

curl -L http://binaries.projectcalico.org/repo/key | apt-key add -

# Add source for binaries.projectcalico.org, removing the priority files that
# were automatically created by the fuel plugin installer (the version number
# in the file names causes problems as it contains full stops, and the file
# contents aren't what we want).

rm -f /etc/apt/preferences.d/calico-fuel-plugin-2.0.0 /etc/apt/sources.list.d/calico-fuel-plugin-2.0.0.list

cat > /etc/apt/sources.list.d/calico.list <<EOF
deb http://binaries.projectcalico.org/fuel7.0 ./
EOF

cat << PREFS >> /etc/apt/preferences.d/calico-fuel
Package: *
Pin: origin binaries.projectcalico.org
Pin-Priority: 1200
PREFS

# Add PPA for the etcd packages, and ensure that it has lower priority than
# binaries.projectcalico.org so that we get the fuel versions of the calico
# packages.

apt-add-repository -y ppa:project-calico/kilo

cat > /etc/apt/preferences.d/calico-etcd <<EOF
Package: *
Pin: release o=LP-PPA-project-calico-kilo
Pin-Priority: 1175
EOF

# Pick up package details from new sources.
apt-get update

# Install etcd and configure it for a controller node.

apt-get -y install etcd

service etcd stop
rm -rf /var/lib/etcd/*
awk '/exec \/usr\/bin\/etcd/{while(getline && $0 != ""){}}1' /etc/init/etcd.conf > tmp
mv tmp /etc/init/etcd.conf
cat << EXEC_CMD >> /etc/init/etcd.conf
exec /usr/bin/etcd -name controller                                                                           \\
                   -advertise-client-urls "http://${this_node_address}:2379,http://${this_node_address}:4001" \\
                   -listen-client-urls "http://0.0.0.0:2379,http://0.0.0.0:4001"                              \\
                   -listen-peer-urls "http://0.0.0.0:2380"                                                    \\
                   -initial-advertise-peer-urls "http://${this_node_address}:2380"                            \\
                   -initial-cluster-token fuel-cluster-1                                                      \\
                   -initial-cluster controller=http://${this_node_address}:2380                               \\
                   -initial-cluster-state new
EXEC_CMD

service etcd start

# Ensure that the firewall isn't dropping traffic to the ports used by etcd.
iptables -I INPUT 1 -p tcp --dport 2379 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 2380 -j ACCEPT
iptables -I INPUT 3 -p tcp --dport 4001 -j ACCEPT
iptables-save > /etc/iptables.local
/sbin/iptables-restore < /etc/iptables.local

# Run apt-get upgrade and apt-get dist-upgrade. These commands will
# bring in Calico-specific updates to the OpenStack packages and to
# dnsmasq.

apt-get -y upgrade
apt-get -y dist-upgrade

# Install the calico-control package:

apt-get -y install calico-control

# Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file:
#
#     Find the line beginning with type_drivers, and change it to
#     read type_drivers = local, flat.

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.pre-calico

sed -i "/^type_drivers/d" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "/^\[ml2\]/a\
type_drivers = local, flat
" /etc/neutron/plugins/ml2/ml2_conf.ini

#     Find the line beginning with mechanism_drivers, and change it
#     to read mechanism_drivers = calico.

sed -i "/^mechanism_drivers/d" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "/^\[ml2\]/a\
mechanism_drivers = calico
" /etc/neutron/plugins/ml2/ml2_conf.ini

#     Find the line beginning with tenant_network_types, and change it
#     to read tenant_network_types = local.

sed -i "/^tenant_network_types/d" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "/^\[ml2\]/a\
tenant_network_types = local
" /etc/neutron/plugins/ml2/ml2_conf.ini

# Edit the /etc/neutron/neutron.conf file:
#
#     Find the line for the dhcp_agents_per_network setting,
#     uncomment it, and set its value to the number of compute nodes
#     that you will have (or any number larger than that). This
#     allows a DHCP agent to run on every compute node, which Calico
#     requires because the networks on different compute nodes are
#     not bridged together.

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.pre-calico

sed -i "/^dhcp_agents_per_network/d" /etc/neutron/neutron.conf

sed -i "/^\[DEFAULT\]/a\
dhcp_agents_per_network = 1000
" /etc/neutron/neutron.conf

# Remove api_workers and rpc_workers config, so that these default to
# 0. The Calico/OpenStack plugin doesn't currently work if the
# Neutron server is split across multiple OS processes.

sed -i "/^api_workers/d" /etc/neutron/neutron.conf
sed -i "/^rpc_workers/d" /etc/neutron/neutron.conf

# Set agent_down_time to 60, instead of Fuel's default setting of 15.
# The Calico/OpenStack plugin reports Felix agent status every 30
# seconds, based on the HEARTBEAT exchange between the plugin and each
# Felix; and it is recommended that agent_down_time should be double
# the expected reporting interval.

sed -i "/^agent_down_time/d" /etc/neutron/neutron.conf

sed -i "/^\[DEFAULT\]/a\
agent_down_time = 60
" /etc/neutron/neutron.conf

# If dnspython is installed, eventlet replaces socket.getaddrinfo() with its
# own version that cannot handle IPv6 addresses. As a workaround, we comment
# out the '::1 localhost' line from /etc/hosts.

sed -i "s/^::1\(.*\)/#::1\1 #commented out due to dnspython IPv6 issue/" /etc/hosts

# Restart the neutron server process:

service neutron-server restart

# BIRD installation

gpg --keyserver keyserver.ubuntu.com --recv-keys F9C59A45
gpg -a --export F9C59A45 | apt-key add -

cat > /etc/apt/sources.list.d/bird.list <<EOF
deb http://ppa.launchpad.net/cz.nic-labs/bird/ubuntu trusty main
EOF

apt-get update

apt-get -y install bird

# Allow BGP through the Fuel firewall
iptables -I INPUT 1 -p tcp --dport 179 -j ACCEPT

# Save the current iptables so that they will be restored if the
# controller is rebooted.
iptables-save > /etc/iptables/rules.v4

# Set up a service, calico-fuel-monitor, that will detect changes to the
# deployment and reconfigure the calico components on the controller as
# needed. For example, updating the route reflector configuration after
# compute nodes are added/removed from the deployment.
SERVICE_NAME=calico-fuel-monitor

# Install the service's dependencies.
apt-get -y install python-pip
pip install pyinotify pyaml

# During node deployment, the plugin deployment scripts are copied into 
# /etc/fuel/plugins/<plugin_name>-<plugin_version> on the node, and this
# script is run from that directory.
SERVICE_DIR=$(pwd)
sed -i "s@##REPLACE_ON_INSTALL##@${SERVICE_DIR}@" $SERVICE_NAME
chmod +x $SERVICE_NAME

cat << SERVICE_CFG >> /etc/init/calico-fuel-monitor.conf
# calico-fuel-monitor - daemon to monitor for fuel deployment changes and
#                       reconfigure the calico components accordingly

description "Calico daemon to monitor fuel deployment changes"
author "Emma Gordon <emma@projectcalico.org>"

start on runlevel [2345]
stop on runlevel [016]

respawn

script
cd ${SERVICE_DIR}
exec ./${SERVICE_NAME}
end script
SERVICE_CFG

service $SERVICE_NAME start

exit 0
