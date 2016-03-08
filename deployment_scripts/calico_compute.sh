#!/bin/bash
# Copyright 2015-2016 Metaswitch Networks

export DEBIAN_FRONTEND=noninteractive

exec > /tmp/calico_compute.log 2>&1

set -x

echo "Hi, I'm a compute node!"

this_node_address=$(python get_node_ip.py `hostname`)
controller_node_addresses=$(python get_controller_ips.py)

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

# Install etcd and configure it for a compute node.

apt-get -y install etcd

for controller_address in ${controller_node_addresses[@]}
do
  initial_cluster+="${controller_address}=http://${controller_address}:2380,"
done
initial_cluster=${initial_cluster::-1} # remove trailing comma

service etcd stop
rm -rf /var/lib/etcd/*
awk 'BEGIN{p=1}/exec \/usr\/bin\/etcd/{p=0}/^\s*$/{p=1}p' /etc/init/etcd.conf > tmp
mv tmp /etc/init/etcd.conf
cat << EXEC_CMD >> /etc/init/etcd.conf
exec /usr/bin/etcd -proxy on                                                         \\
                   -listen-client-urls http://127.0.0.1:4001                         \\
                   -advertise-client-urls http://127.0.0.1:7001                      \\
                   -initial-cluster ${initial_cluster}
EXEC_CMD
service etcd start

# Run apt-get upgrade and apt-get dist-upgrade. These commands will
# bring in Calico-specific updates to the OpenStack packages and to
# dnsmasq.

apt-get -y upgrade
apt-get -y dist-upgrade

# Open /etc/nova/nova.conf and remove the linuxnet_interface_driver line.

cp /etc/nova/nova.conf /etc/nova/nova.conf.pre-calico

sed -i "/^linuxnet_interface_driver/d" /etc/nova/nova.conf
service nova-compute restart

# Install some extra packages.

apt-get -y install neutron-common neutron-dhcp-agent nova-api

# Open /etc/neutron/dhcp_agent.ini in your preferred text editor. In
# the [DEFAULT] section, add the following line:
#
# interface_driver = neutron.agent.linux.interface.RoutedInterfaceDriver

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.pre-calico

sed -i "/^interface_driver/d" /etc/neutron/dhcp_agent.ini

sed -i "/^\[DEFAULT\]/a\
interface_driver = neutron.agent.linux.interface.RoutedInterfaceDriver
" /etc/neutron/dhcp_agent.ini

# Allow BGP connections through the Fuel firewall. We do this before
# installing calico-compute, so that they will be included when the
# calico-compute install script does iptables-save.
iptables -I INPUT 1 -p tcp --dport 179 -j ACCEPT

# Add sources for BIRD and Ubuntu Precise.

gpg --keyserver keyserver.ubuntu.com --recv-keys F9C59A45
gpg -a --export F9C59A45 | apt-key add -

cat > /etc/apt/sources.list.d/bird.list <<EOF
deb http://ppa.launchpad.net/cz.nic-labs/bird/ubuntu trusty main
EOF

cat > /etc/apt/sources.list.d/trusty.list <<EOF
deb http://gb.archive.ubuntu.com/ubuntu/ trusty main
deb http://gb.archive.ubuntu.com/ubuntu/ trusty universe
EOF

apt-get update

# Install BIRD and calico-compute packages.

# Note that this will trigger the installation of iptables-persistent which
# will attempt to bring up a dialog box. We use debconf-set-selections to set
# the value beforehand to avoid this (so not to interrupt the automated
# installation process).
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

apt-get -y install calico-compute bird

# Configure BIRD. By default Calico assumes that you'll be deploying
# a route reflector to avoid the need for a full BGP mesh. To this
# end, it includes useful configuration scripts that will prepare a
# BIRD config file with a single peering to the route reflector. If
# that's correct for your network, you can run the following command
# for IPv4 connectivity between compute hosts.
#
# The calico_route_reflector.sh script will set up the required BGP
# Route Reflctor configuration on the controller to allow connections
# from the compute nodes.
#
# If you are configuring a full BGP mesh you'll need to handle the BGP
# configuration appropriately - by editing this script/the Route Reflector
# script. You should consult the relevant documentation for your chosen BGP
# stack.

calico-gen-bird-mesh-conf.sh $this_node_address 64511 ${controller_node_addresses[@]}

# Edit the /etc/calico/felix.cfg file:
#     Change the MetadataAddr setting to 127.0.0.1.
#     Change the MetadataPort setting to 8775.

cp /etc/calico/felix.cfg.example /etc/calico/felix.cfg

sed -i "/^MetadataAddr/d" /etc/calico/felix.cfg
sed -i "/^\[global\]/a\
MetadataAddr = 127.0.0.1
" /etc/calico/felix.cfg

sed -i "/^MetadataPort/d" /etc/calico/felix.cfg
sed -i "/^\[global\]/a\
MetadataPort = 8775
" /etc/calico/felix.cfg

# Restart the Felix service:
service calico-felix restart

exit 0
