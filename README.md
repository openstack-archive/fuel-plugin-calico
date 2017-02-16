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

For more details, see [projectcalico.org](http://www.projectcalico.org).

Limitations:
------------

None.

Compatible versions:
--------------------

	Mirantis Fuel 9.0

To build the plugin:
--------------------

- Install the fuel plugin builder, fpb:

		easy_install pip
		pip install fuel-plugin-builder

- Clone the calico plugin repository and run the plugin builder:

		git clone https://github.com/openstack/fuel-plugin-calico
		cd fuel-plugin-calico/
		fpb --build .

- Check that the file fuel-plugin-calico-VERSION.noarch.rpm was created.


To install the plugin:
----------------------

- Prepare a clean fuel master node.

- Copy the plugin onto the fuel master node:

		scp fuel-plugin-calico-VERSION.noarch.rpm root@<Fuel_Master_Node_IP>:/tmp

- Install the `patch` utility:

        yum install -y patch

- Install the plugin on the fuel master node:

		cd /tmp
		fuel plugins --install fuel-plugin-calico-VERSION.noarch.rpm

- Check the plugin was installed:

		fuel plugins --list


User Guide
----------

To deploy a cluster with the Calico plugin, use the Fuel web UI to deploy an
OpenStack cluster in the usual way, with the following guidelines:

- Create a new OpenStack environment, selecting:

        Mitaka on Ubuntu 14.04
        "Calico networking" as the networking setup

- Under the network tab, configure the `Public` settings to reduce
  Floating-IP addresses pool to one address,
  because Calico does not support Floating IPs use-case.
  For example (exact values will
  depend on your setup):

        Node Network Group
          default:
            CIDR: 172.18.203.0/24
            IP Range: 172.18.203.2 - 172.18.203.253
            Gateway: 172.18.203.1
            Use VLAN tagging: No

        Settings
          Neutron L3:
            Floating IP range: 172.18.203.254 - 172.18.203.254

- Under the network tab, configure the `Private` network settings
  (this network will be used for BGP peering between custer nodes, route
  reflectors and external peers, configured by UI). Do not forget to exclude
  Your BGP peers and gateway from the IP range!
  For example (exact values will depend on your setup):

        IP Range: 172.100.203.33 - 172.100.203.254
        CIDR: 172.100.203.0/24
        Use VLAN tagging: No

- Under Fuel CLI, configure gateway for `Private` network.
  This gateway will be used for pass outgoing external traffic from instances.
  In most cases the same gateway node should be also an external BGB peer
  (see below, external BGB peer-1).

        [root@nailgun ~]# fuel2 network-group list
        +----+---------+------------+------------------+---------+----------+
        | id | name    | vlan_start | cidr             | gateway | group_id |
        +----+---------+------------+------------------+---------+----------+
        |  5 | private | None       | 172.100.203.0/24 | None    | 1        |
        +----+---------+------------+------------------+---------+----------+
        [root@nailgun ~]# fuel2 network-group update -g 172.100.203.1  5
        +------------+------------------+
        | Field      | Value            |
        +------------+------------------+
        | id         | 5                |
        | name       | private          |
        | vlan_start | None             |
        | cidr       | 172.100.203.0/24 |
        | gateway    | 172.100.203.1    |
        | group_id   | 1                |
        +------------+------------------+

- Under the network tab, configure IP pool for Calico network fabric.
  Ip addresses from this pool will be assigned to VM instances:

        Settings
          Neutron L3:
            Admin Tenant network CIDR: 10.10.0.0/16
            Admin Tenant network gateway: 10.10.0.1

- Under the network tab, in the `other/Calico_networking` section setup
  AS number, external BGP peering and another Calico networking options.

        AS Number: 64513

        [X] Allow external BGP peering
            External BGP peers:
              peer-1:65000:172.100.203.1
              peer-2:65002:172.100.203.13

- Add nodes (for meaningful testing, you will need at least two compute nodes
  in addition to the controller). Calico-RR (route-reflector) and Calico-ETCD
  node roles may be co-located on Controller nodes or deployed separately.

- Under the nodes tab, configure networks to NICs mapping
  (exact positions will depend on your setup)

- Deploy changes

- Do not forget to configure BGP peering session on you infrastructure
  BGP peers.
