Calico plugin for Mirantis Fuel
===============================

Calico provides seamless, scalable, secure Layer 3 Virtual Networking for your
Mirantis OpenStack Deployment.

By replacing OpenStack’s native networking model, Calico targets deployments 
where the vast majority of workloads only require L3 connectivity, providing 
efficient, easy to troubleshoot networking, without the complexity and 
inefficiency of overlay networking models. Calico does not require any 
additional nodes or Calico specific management – it just works, and gets out 
of your way!

Limitations:
------------

In the current release, Calico requires a deployment with a single OpenStack
controller. This limitation will be lifted in future releases.

Compatible versions:
--------------------

	Mirantis Fuel 6.1


To build the plugin:
--------------------

- Install the fuel plugin builder, fpb:

		easy_install pip

		pip install fuel-plugin-builder

- Clone the calico plugin repository and run the plugin builder:

		git clone https://github.com/stackforge/fuel-plugin-calico

		cd fuel-plugin-calico/

		fpb --build .

- Check that the file calico-fuel-plugin-1.0-1.0.0-0.noarch.rpm was created.


To install the plugin:
----------------------

- Prepare a clean fuel master node.

- Copy the plugin onto the fuel master node:

		scp calico-fuel-plugin-1.0-1.0.0-0.noarch.rpm root@<Fuel_Master_Node_IP>:/tmp

- Install the plugin on the fuel master node:

		cd /tmp

		fuel plugins --install calico-fuel-plugin-1.0-1.0.0-0.noarch.rpm

- Check the plugin was installed:

		fuel plugins --list


User Guide
----------

To deploy a cluster with the Calico plugin, use the Fuel web UI to deploy an
OpenStack cluster in the usual way, with the following guidelines:

- Create a new OpenStack environment, selecting:

	Juno on Ubuntu Trusty

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
  in addition to the controller). Note that, in this release of Calico, only
  a single controller node is supported.

- Deploy changes
