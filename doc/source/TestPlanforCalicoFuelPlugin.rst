============================================
Test Plan for the Calico Fuel Plugin ver 2.0
============================================

Calico Plugin
=============

Calico presents a new approach to virtual networking, based on the same
scalable IP networking principles as the Internet. It targets data centers
where most of the workloads (VMs, containers or bare metal servers) only
require IP connectivity, and provides that using standard IP routing. Isolation
between workloads - whether according to tenant ownership, or any finer grained
policy - is achieved by iptables programming at the servers hosting the source
and destination workloads.

Developer's specification
=========================

Is available on `GitHub`_.

.. _GitHub: https://github.com/stackforge/fuel-plugin-calico/blob/master/specs/calico-fuel-plugin.rst

Test strategy
=============

At present, all plugin-specific tests are manual, and are concerned with
establishing basic Calico function.  The Calico project has a large number of
manual and automated tests which cover its function, security and performance -
this test plan does not replicate those tests.

Acceptance criteria
-------------------

All tests should pass.

Test environment, infrastructure and tools
------------------------------------------

All tests run in a single environment.  This is a Mirantis OpenStack cluster
with a Fuel master node, one controller node, and two or more compute nodes.
The cluster should be deployed with the Calico plugin enabled, as follows:

#. Create a new OpenStack environment, selecting:

   - Kilo on Ubuntu Trusty

   - "Neutron with VLAN segmentation" as the networking setup.

#. Under the Settings tab, make sure the following options are checked:

   - "Assign public network to all nodes"

   - "Use Calico Virtual Networking"

#. Under the Network tab, configure the 'Public' settings (leaving all of the
   other sections with their default values):

   - IP Range: 172.18.203.60 - 172.18.203.69

   - CIDR: 172.18.203.0/24

   - Use VLAN tagging: No

   - Gateway: 172.18.203.1

   - Floating IP range: 172.18.203.70 - 172.18.203.79

#. Add one controller and two compute nodes.

#. Deploy changes.

Once the cluster has deployed, go to Project->Network->Networks in the
OpenStack web UI and create a network and subnet from which instance IP
addresses will be allocated. Use the following settings:

- Name: demo
- IP subnet: 10.65.0.0/24
- Gateway: 10.65.0.1
- DHCP-enabled: Yes

Also in the OpenStack web UI, under Project->Compute->Access&Security, create
two new security groups named 'sg1' and 'sg2', both with description
'test'. For each security group, select 'Manage Rules' and add two new rules
using the following settings:

- First Rule:

  - Rule: ALL ICMP
  - Direction: Ingress
  - Remote: Security Group
  - Security Group: <whichever of sg1/sg2 is followed by '(current)'>
  - Ether Type: IPv4

- Second Rule:

  - Rule: SSH
  - Remote: CIDR
  - CIDR: 0.0.0.0/0

Product compatibility matrix
----------------------------

The plugin is compatible with MOS 7.0.  This test plan is executed against MOS
7.0 GA plus mu-2.

Type of testing
===============

As above, this test plan is concerned with establishing that Calico networking
has been successfully deployed.  Security, performance, and detailed functional
testing are covered by the main Project Calico test plan.

Build Plugin
------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | build_plugin                                                     |
+------------------+------------------------------------------------------------------+
| Description      | Verify that the plugin builds successfully.                      |
+------------------+------------------------------------------------------------------+
| Steps            | 1. git clone https://github.com/openstack/fuel-plugin-calico.git |
|                  | 2. pushd fuel-plugin-calico; git checkout 7.0; popd              |
|                  | 3. fpb --build fuel-plugin-calico                                |
+------------------+------------------------------------------------------------------+
| Expected Result  | Outputs the message 'Plugin is built' and the                    |
|                  | calico-fuel-plugin-2.0-2.0.2-1.noarch.rpm package is created in  |
|                  | the fuel-plugin-calico directory.                                |
+------------------+------------------------------------------------------------------+

Install Plugin
--------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | install_plugin                                                   |
+------------------+------------------------------------------------------------------+
| Description      | Verify that the plugin installs successfully.                    |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Copy the plugin package into /tmp on the Fuel Master Node.    |
|                  | 2. SSH onto the Fuel Master Node.                                |
|                  | 3. fuel plugins --install \                                      |
|                  |    /tmp/calico-fuel-plugin-2.0-2.0.2-1.noarch.rpm                |
|                  | 4. fuel plugins --list                                           |
+------------------+------------------------------------------------------------------+
| Expected Result  | Output from step 4 should be::           	             	      |
|                  |                                         	             	      |
|                  | 	 id | name               | version | package_version 	      |
|                  | 	 ---|--------------------|---------|---------------- 	      |
|                  | 	 1  | calico-fuel-plugin | 2.0.2   | 3.0.0                    |
+------------------+------------------------------------------------------------------+

Verify Calico option in Fuel web UI
-----------------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | verify_calico_in_fuel_web_ui                                     |
+------------------+------------------------------------------------------------------+
| Description      | Verify that the Calico plugin appears in the Fuel UI.            |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Create a new OpenStack environment in the Fuel web UI.        |
|                  | 2. Navigate to the Settings tab.                                 |
+------------------+------------------------------------------------------------------+
| Expected Result  | There should be a tick box labelled 'Use Calico Virtual 	      |
|                  | Networking'.                            	             	      |
+------------------+------------------------------------------------------------------+

Deploy OpenStack with Calico
----------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | deploy_openstack_with_calico                                     |
+------------------+------------------------------------------------------------------+
| Description      | Verify that an OpenStack environment can be successfully         |
|                  | deployed with the Calico plugin enabled.                         |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Create a new OpenStack environment in the Fuel web UI and     |
|                  |    configure/deploy as per the instructions in the 'Test         |
|                  |    environment, infrastructure and tools' section of this test   |
|                  |    plan.                                                         |
+------------------+------------------------------------------------------------------+
| Expected Result  | 'Success' message is displayed in the Fuel web UI. Followed by:  |
|                  | 'Deployment of environment 'test' is done.  Access the OpenStack |
|                  | dashboard (Horizon) at ...'                 	              |
+------------------+------------------------------------------------------------------+

Verify BGP Sessions
-------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | verify_bgp_sessions                                              |
+------------------+------------------------------------------------------------------+
| Description      | Verify that there is a BGP route reflector running on the        |
|                  | controller node, and that it has established peer connections to |
|                  | the compute nodes.                                               |
+------------------+------------------------------------------------------------------+
| Steps            | 1. SSH onto the controller node from the Fuel master node.       |
|                  | 2. Enter the command 'birdc', followed by 'show protocols all'.  |
|                  | 3. Check the output details show two established BGP sessions -  |
|                  |    one to each compute node.                                     |
+------------------+------------------------------------------------------------------+
| Expected Result  | There is a running route reflector on the controller node, with  |
|                  | established BGP peer connections to the two compute nodes.       |
+------------------+------------------------------------------------------------------+

Create VMs
----------

+------------------+------------------------------------------------------------------+
| Test Case ID     | create_vms                                                       |
+------------------+------------------------------------------------------------------+
| Description      | Verify that Calico does not interfere with the creation of new   |
|                  | VMs.                                                             |
+------------------+------------------------------------------------------------------+
| Steps            | 1. In the OpenStack web UI, go to Project->Instances.            |
|                  | 2. Launch a batch of 6 VMs with the following details.           |
|                  |                                                                  |
|                  |    - Flavor: m1.tiny                                             |
|                  |                                                                  |
|                  |    - Boot from image: TestVM                                     |
|                  |                                                                  |
|                  |    - Under the Networking tab, drag 'demo' into the 'Selected    |
|                  |      Networks' box.                                              |
|                  |                                                                  |
|                  |    - Under the Access & Security tab, select either 'sg1' or     |
|                  |      'sg2' as the security group, such that roughly half of the  |
|                  |      VMs are in each security group.                             |
|                  |                                                                  |
|                  | 3. Under Admin->Instances, verify that:                          |
|                  |                                                                  |
|                  |    - the requested 6 VMs (aka instances) have been launched      |
|                  |                                                                  |
|                  |    - they are distributed roughly evenly across the two compute  |
|                  |      hosts                                                       |
|                  |                                                                  |
|                  |    - they have each been assigned an IP address from the range   |
|                  |      that you configured above (e.g. 10.65.0/24)                 |
|                  |                                                                  |
|                  |    - they reach Active status within about a minute.             |
+------------------+------------------------------------------------------------------+
| Expected Result  | The VMs are correctly distributed, and activate in a reasonable  |
|                  | time.                                       	              |
+------------------+------------------------------------------------------------------+

Test connectivity
-----------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | test_connectivity                                                |
+------------------+------------------------------------------------------------------+
| Description      | Verify that Calico has configured the network routing to allow   |
|                  | communication between the VMs.                                   |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Log on to one of the VMs, for example using SSH from that     |
|                  |    VM's compute host.                                            |
|                  | 2. Use 'ping' to verify connectivity to the IP address of each   |
|                  |    of the other VMs in the same security group.                  |
+------------------+------------------------------------------------------------------+
| Expected Result  | Ping responses are received from all the VMs in the same         |
|                  | security group.                             	              |
+------------------+------------------------------------------------------------------+

Test security
-------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | test_security                                                    |
+------------------+------------------------------------------------------------------+
| Description      | Verify that Calico correctly enforces the configured security    |
|                  | rules.                                                           |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Log on to one of the VMs, for example using SSH from that     |
|                  |    VM's compute host.                                            |
|                  | 2. Use 'ping' to verify lack of connectivity to the IP address   |
|                  |    of each of the VMs in the other security group.               |
+------------------+------------------------------------------------------------------+
| Expected Result  | Ping responses are not received from any of the VMs in the other |
|                  | security group.                             	              |
+------------------+------------------------------------------------------------------+

Test Initial Route Reflector Configuration
------------------------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | test_initial_rr_config                                           |
+------------------+------------------------------------------------------------------+
| Description      | Verify that BIRD's BGP peer configuration is correct.            |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Deploy an environment with 1 controller, 1 compute node and   |
|                  |    one storage node.                                             |
|                  | 2. Verify that the BIRD instance on the controller is configured |
|                  |    with only one peer (the compute node).                        |
+------------------+------------------------------------------------------------------+
| Expected Result  | BGP peer configuration is created only for compute nodes.        |
+------------------+------------------------------------------------------------------+

Test Route Reflector Configuration Changes
------------------------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | test_rr_config_changes                                           |
+------------------+------------------------------------------------------------------+
| Description      | Verify that BIRD's BGP peer configuration is updated correctly   |
|                  | after a change to the deployment.                                |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Deploy an environment with 1 controller and 1 compute node.   |
|                  | 2. Verify that the BIRD instance on the controller is configured |
|                  |    with only one peer (the compute node).                        |
|                  | 3. Add a compute node and re-deploy.                             |
|                  | 4. Verify that the BIRD instance on the controller is now        |
|                  |    configured with two peers (both compute nodes).               |
|                  | 5. Delete both compute nodes and re-deploy.                      |
|                  | 6. Add a storage node and re-deploy.                             |
|                  | 7. Verify that the BIRD instance on the controller is now        |
|                  |    configured with no peers.                                     |
+------------------+------------------------------------------------------------------+
| Expected Result  | New BGP peer configuration is added to the BIRD instance on the  |
|                  | controller when a compute node is added to the deployment.       |
+------------------+------------------------------------------------------------------+

External connectivity
---------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | test_external_connectivity                                       |
+------------------+------------------------------------------------------------------+
| Description      | Verify that a VM can connect to an address outside the cluster.  |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Create a VM, as in the 'Create VMs' test above.               |
|                  | 2. SSH to that VM's compute host.                                |
|                  | 3. Execute the following to allow the compute host to do NAT     |
|                  |    for traffic from local VMs to the outside world::             |
|                  |                                                                  |
|                  |        iptables -t nat -A POSTROUTING -s 10.65.0/24 \            |
|                  |            ! -d 10.65.0/24 -o br-ex -j MASQUERADE                |
|                  |                                                                  |
|                  |    (If you configured an IP subnet other than 10.65.0/24 for     |
|                  |    your VMs, use that subnet here instead of '10.65.0/24'.)      |
|                  |                                                                  |
|                  | 4. Log on to the VM, using SSH from the compute host.            |
|                  | 5. Run 'ping 8.8.8.8'.                                           |
+------------------+------------------------------------------------------------------+
| Expected Result  | The VM gets ping responses from 8.8.8.8.                         |
|                  |                                             	              |
|                  | Note that in a full Calico deployment, NAT like this would be    |
|                  | configured on the border gateways between the data center and    |
|                  | the outside world, instead of on each compute host.  Hence the   |
|                  | Calico agent does not automatically configure iptables rules     |
|                  | like the one used here on each compute host.  For the purposes   |
|                  | of testing in a small Fuel cluster, however, programming the NAT |
|                  | directly on the compute host demonstrates the principle of how   |
|                  | Calico external connectivity works.                              |
+------------------+------------------------------------------------------------------+

Mandatory Tests
===============

Install plugin and deploy environment
-------------------------------------

Covered above.

Modifying env with enabled plugin (removing/adding controller nodes)
--------------------------------------------------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | modify_env_with_plugin_remove_add_controller                     |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Install the Calico plugin on the Fuel master node.            |
|                  | 2. Using the Fuel UI, create an environment with the Calico      |
|                  |    plugin enabled, editing the network and settings              |
|                  |    configuration as above.                                       |
|                  | 3. Add 1 controller and 2 compute nodes.                         |
|                  | 4. Deploy the cluster.                                           |
|                  | 5. Run the 'Create VMs', 'Test connectivity' and 'Test security' |
|                  |    tests above - all should pass.                                |
|                  | 6. Add a second controller, and re-deploy the cluster.           |
|                  | 7. Create another VM in each security group (sg1 and sg2).       |
|                  | 8. Run the 'Test connectivity' and 'Test security' tests again - |
|                  |    all should pass.                                              |
|                  | 9. Delete the original controller, and re-deploy the cluster.    |
|                  | 10. Add a new controller, and re-deploy the cluster.             |
|                  | 11. Create another VM in each security group (sg1 and sg2).      |
|                  | 12. Run the 'Test connectivity' and 'Test security' tests again  |
|                  |     - all should pass.                                           |
+------------------+------------------------------------------------------------------+
| Expected Result  | The Calico plugin is installed successfully, the cluster is      |
|                  | created, and all plugin services are enabled and working as      |
|                  | expected after modifying the environment.                        |
+------------------+------------------------------------------------------------------+

Modifying env with enabled plugin (removing/adding compute nodes)
-----------------------------------------------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | modify_env_with_plugin_remove_add_compute                        |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Install the Calico plugin on the Fuel master node.            |
|                  | 2. Using the Fuel UI, create an environment with the Calico      |
|                  |    plugin enabled, editing the network and settings              |
|                  |    configuration as above.                                       |
|                  | 3. Add 1 controller and 2 compute nodes.                         |
|                  | 4. Deploy the cluster.                                           |
|                  | 5. Run the 'Create VMs', 'Test connectivity' and 'Test security' |
|                  |    tests above - all should pass.                                |
|                  | 6. Terminate the created VM instances.                           |
|                  | 7. Remove 1 compute node.                                        |
|                  | 8. Re-deploy the cluster.                                        |
|                  | 9. Run the 'Create VMs', 'Test connectivity' and 'Test security' |
|                  |    tests above - all should pass.  (Note all VMs will be         |
|                  |    created on the same compute node, as there is now only one.)  |
|                  | 10. Terminate the created VM instances.                          |
|                  | 11. Add 1 compute node.                                          |
|                  | 12. Re-deploy the cluster.                                       |
|                  | 13. Run the 'Create VMs', 'Test connectivity' and 'Test          |
|                  |     security' tests above - all should pass.                     |
+------------------+------------------------------------------------------------------+
| Expected Result  | The Calico plugin is installed successfully, the cluster is      |
|                  | created, and all plugin services are enabled and working as      |
|                  | expected after modifying the environment.                        |
+------------------+------------------------------------------------------------------+


Uninstall of plugin with deployed environment
---------------------------------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | uninstall_plugin_with_deployed_env                               |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Install the Calico plugin.                                    |
|                  | 2. As above, deploy an environment with the Calico plugin        |
|                  |    enabled.                                                      |
|                  | 3. Run the 'Create VMs', 'Test connectivity' and 'Test security' |
|                  |    tests above - all should pass.                                |
|                  | 4. Try to remove the Calico plugin:                              |
|                  |    fuel plugins --remove calico-fuel-plugin==2.0.0               |
|                  |    This should fail with the                                     |
|                  |    error message: "400 Client Error: Bad Request (Can't delete   |
|                  |    plugin which is enabled for some environment.)".  Verify that |
|                  |    the Calico plugin is still installed.                         |
|                  | 5. Remove the environment.                                       |
|                  | 6. Remove the Calico plugin.                                     |
|                  | 7. Check the Calico plugin was successfully removed.             |
+------------------+------------------------------------------------------------------+
| Expected Result  | Plugin is installed successfully.  An error message is present   |
|                  | when we attempt to remove a plugin which is attached to an       |
|                  | enabled environment, and the plugin is not removed.  When the    |
|                  | environment is removed, the plugin can be removed successfully.  |
+------------------+------------------------------------------------------------------+

Uninstall of plugin
-------------------

+------------------+------------------------------------------------------------------+
| Test Case ID     | uninstall_plugin                                                 |
+------------------+------------------------------------------------------------------+
| Steps            | 1. Install the Calico plugin.                                    |
|                  | 2. Check that it was installed successfully.                     |
|                  | 3. Remove the Calico plugin.                                     |
|                  | 4. Check that it was successfully removed.                       |
+------------------+------------------------------------------------------------------+
| Expected Result  | Plugin was installed and then removed successfully.              |
+------------------+------------------------------------------------------------------+

Appendix
========

Project Calico - `http://www.projectcalico.org/`_

Calico Documentation - `http://docs.projectcalico.org/en/latest/index.html`_

Calico GitHub - `https://github.com/projectcalico/calico`_

.. _http://www.projectcalico.org/: http://www.projectcalico.org/
.. _http://docs.projectcalico.org/en/latest/index.html: http://docs.projectcalico.org/en/latest/index.html
.. _https://github.com/projectcalico/calico: https://github.com/projectcalico/calico

Revision history
================

+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| Version | Revision date | Editor                                          | Comment                                              |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.1     | 23.01.2015    | Irina Povolotskaya (ipovolotskaya@mirantis.com) | Created the template structure.                      |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.2     | 29.04.2015    | Joe Marshall (joemarshall@projectcalico.org)    | First draft.                                         |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.3     | 08.05.2015    | Emma Gordon (emma@projectcalico.org)            | Additional test cases.                               |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.4     | 02.07.2015    | Emma Gordon (emma@projectcalico.org)            | Added new mandatory test cases for all Fuel plugins. |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.5     | 03.08.2015    | Emma Gordon (emma@projectcalico.org)            | Added new test cases.                                |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.6     | 19.02.2016    | Neil Jerram (neil@projectcalico.org)            | First RST version, for plugin version 2.0.           |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
| 0.7     | 14.03.2016    | Dave Langridge (dave@projectcalico.org)         | Fixed typos, and clarified some tests.               |
+---------+---------------+-------------------------------------------------+------------------------------------------------------+
