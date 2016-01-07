WARNING - UNDER DEVLOPMENT:
===========================
This is the development branch for the Calico plugin for the Fuel 7.0 release. 
For a stable, working Calico plugin that has been certified by Mirantis to work 
with the Fuel 6.1 release, you should see the 6.1 branch of this repository.


Calico plugin for Mirantis Fuel
===============================
Calico’s pure L3 approach to data center networking integrates seamlessly with
Mirantis OpenStack to bring simple, scalable and secure networking to your
deployment.

Based on the same scalable IP network principles as the Internet, Calico
implements a highly efficient vRouter in each compute node that leverages the
existing Linux kernel forwarding engine without the need for vSwitches. Each
vRouter propagates workload reachability information (routes) to the rest of
the data center using BGP – either directly in small scale deployments or
via BGP route reflectors to reach Internet level scales in large deployments.

Calico peers directly with the data center’s physical fabric (whether L2 or
L3) without the need for on/off ramps, NAT, tunnels, or overlays.

With Calico, networking issues are easy to troubleshoot. Since it's all IP,
standard tools such as ping and traceroute will just work.

Calico supports rich and flexible network policy which it enforces using
bookended ACLs on each compute node to provide tenant isolation, security
groups, and external reachability constraints.

Limitations:
------------

None.

Compatible versions:
--------------------

	Mirantis Fuel 7.0

To build the plugin:
--------------------

- Install the fuel plugin builder, fpb:

		easy_install pip

		pip install fuel-plugin-builder

- Clone the calico plugin repository and run the plugin builder:

		git clone https://github.com/openstack/fuel-plugin-calico

		cd fuel-plugin-calico/

		fpb --build .

- Check that the file calico-fuel-plugin-2.0-2.0.0-0.noarch.rpm was created.


To install the plugin:
----------------------

- Prepare a clean fuel master node.

- Copy the plugin onto the fuel master node:

		scp calico-fuel-plugin-2.0-2.0.0-0.noarch.rpm root@<Fuel_Master_Node_IP>:/tmp

- Install the plugin on the fuel master node:

		cd /tmp

		fuel plugins --install calico-fuel-plugin-2.0-2.0.0-0.noarch.rpm

- Check the plugin was installed:

		fuel plugins --list


User Guide
----------

To deploy a cluster with the Calico plugin, use the Fuel web UI to deploy an
OpenStack cluster in the usual way, with the following guidelines:

- Create a new OpenStack environment, selecting:

	Kilo on Ubuntu Trusty

	"Neutron with VLAN segmentation" as the networking setup

- Under the settings tab, make sure the following options are checked:

	"Assign public network to all nodes"

	"Use Calico Virtual Networking"

- Under the network tab, configure the 'Public' settings (leaving all of the 
  other sections with their default values). For example (exact values will
  depend on your setup):

	- IP Range: 172.18.203.60 - 172.18.203.69
        - CIDR: 172.18.203.0/24
        - Use VLAN tagging: No
        - Gateway: 172.18.203.1 
	- Floating IP range: 172.18.203.70 - 172.18.203.79

- Add nodes (for meaningful testing, you will need at least two compute nodes
  in addition to the controller).

- Deploy changes
