#!/bin/bash

exec > /tmp/calico_compute.log 2>&1

set -x

echo "Hi, I'm a compute node!"

this_node_address=$(python get_node_ip.py `hostname`)
controller_node_address=$(python get_controller_ip.py)

# Get APT key for binaries.projectcalico.org.

curl -L http://binaries.projectcalico.org/repo/key | apt-key add -

# Add source for binaries.projectcalico.org.

rm /etc/apt/preferences.d/calico-1.0.0 /etc/apt/sources.list.d/calico-1.0.0.list

cat > /etc/apt/sources.list.d/calico.list <<EOF
deb http://binaries.projectcalico.org/fuel6.1 ./
EOF

cat << PREFS >> /etc/apt/preferences.d/calico-fuel
Package: *
Pin: origin binaries.projectcalico.org
Pin-Priority: 1100
PREFS

# Add PPA for the etcd packages, and ensure that it has lower priority than
# binaries.projectcalico.org so that we get the fuel versions of the calico
# packages.

apt-add-repository -y ppa:project-calico/juno

cat > /etc/apt/preferences.d/calico-etcd <<EOF
Package: *
Pin: origin ppa:project-calico/juno
Pin-Priority: 1075
EOF

# Pick up package details from new sources.
apt-get update

# Install etcd and configure it for a compute node.

apt-get -y install etcd

service etcd stop
rm -rf /var/lib/etcd/*
awk '/exec \/usr\/bin\/etcd/{while(getline && $0 != ""){}}1' /etc/init/etcd.conf > tmp
mv tmp /etc/init/etcd.conf
cat << EXEC_CMD >> /etc/init/etcd.conf
exec /usr/bin/etcd -proxy on                                                         \\
                   -listen-client-urls http://127.0.0.1:4001                         \\
                   -initial-cluster controller=http://${controller_node_address}:2380
EXEC_CMD
service etcd start

# Run apt-get upgrade and apt-get dist-upgrade. These commands will
# bring in Calico-specific updates to the OpenStack packages and to
# dnsmasq. 

rm /etc/apt/preferences.d/calico-1.0.0 /etc/apt/sources.list.d/calico-1.0.0.list
apt-get -y upgrade
apt-get -y dist-upgrade

# Open /etc/nova/nova.conf and remove the linuxnet_interface_driver line.

cp /etc/nova/nova.conf /etc/nova/nova.conf.pre-calico

sudo sed -i "/^linuxnet_interface_driver/d" /etc/nova/nova.conf
service nova-compute restart

# If they're running, stop the Open vSwitch services:

# service openvswitch-switch stop
# service neutron-plugin-openvswitch-agent stop

# Then, prevent the services running if you reboot:

# sudo sh -c "echo 'manual' > /etc/init/openvswitch-switch.override"
# sudo sh -c "echo 'manual' > /etc/init/openvswitch-force-reload-kmod.override"
# sudo sh -c "echo 'manual' > /etc/init/neutron-plugin-openvswitch-agent.override"

# Install some extra packages.

apt-get -y install neutron-common neutron-dhcp-agent nova-api-metadata

# Open /etc/neutron/dhcp_agent.ini in your preferred text editor. In
# the [DEFAULT] section, add the following line:
#
# interface_driver = neutron.agent.linux.interface.RoutedInterfaceDriver

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.pre-calico

sudo sed -i "/^interface_driver/d" /etc/neutron/dhcp_agent.ini

sudo sed -i "/^\[DEFAULT\]/a\
interface_driver = neutron.agent.linux.interface.RoutedInterfaceDriver
" /etc/neutron/dhcp_agent.ini

# Allow BGP and Calico API connections through the Fuel firewall.  We
# do this before installing calico-compute, so that they will be
# included when the calico-compute install script does iptables-save.
iptables -I INPUT 1 -p tcp --dport 179 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 9902 -j ACCEPT

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
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

apt-get -y install calico-compute bird

# Configure BIRD. By default Calico assumes that you'll be deploying
# a route reflector to avoid the need for a full BGP mesh. To this
# end, it includes useful configuration scripts that will prepare a
# BIRD config file with a single peering to the route reflector. If
# that's correct for your network, you can run either or both of the
# following commands. For IPv4 connectivity between compute hosts:

calico-gen-bird-conf.sh $this_node_address $controller_node_address 64511

# And/or for IPv6 connectivity between compute hosts:
#
# calico-gen-bird6-conf.sh <compute_node_ipv4> <compute_node_ipv6> <route_reflector_ipv6> <bgp_as_number>
#
# Note that you'll also need to configure your route reflector to
# allow connections from the compute node as a route reflector
# client. This configuration is outside the scope of this install
# document.
#
# If you are configuring a full BGP mesh you'll need to handle the
# BGP configuration appropriately. You should consult the relevant
# documentation for your chosen BGP stack.

# Edit the /etc/calico/felix.cfg file:
#
#     Change both the PluginAddress and ACLAddress settings to the
#     host name or IP address of the controller node.

cp /etc/calico/felix.cfg.example /etc/calico/felix.cfg

sudo sed -i "/^PluginAddress/d" /etc/calico/felix.cfg
sudo sed -i "/^\[global\]/a\
PluginAddress = $controller_node_address
" /etc/calico/felix.cfg

sudo sed -i "/^ACLAddress/d" /etc/calico/felix.cfg
sudo sed -i "/^\[global\]/a\
ACLAddress = $controller_node_address
" /etc/calico/felix.cfg

#     Change the MetadataAddr setting to 127.0.0.1.

sudo sed -i "/^MetadataAddr/d" /etc/calico/felix.cfg
sudo sed -i "/^\[global\]/a\
MetadataAddr = 127.0.0.1
" /etc/calico/felix.cfg

#     Change the MetadataPort setting to 8775.

sudo sed -i "/^MetadataPort/d" /etc/calico/felix.cfg
sudo sed -i "/^\[global\]/a\
MetadataPort = 8775
" /etc/calico/felix.cfg

#     Now, restart the Felix service with:

service calico-felix restart

exit 0
