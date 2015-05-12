Fuel Plugin for Project Calico
==============================

The Calico plugin provides the ability to use Calico as a networking backend
for Mirantis OpenStack.

Compatible with Fuel version 6.1.

Problem description
===================

Calico is a new approach to virtual networking, based on the same scalable IP
networking principles as the Internet. It targets data centers where most of
the workloads (VMs, containers or bare metal servers) only require IP
connectivity, and provides that using standard IP routing. Isolation between
workloads - whether according to tenant ownership, or any finer grained
policy - is achieved by iptables programming at the servers hosting the source
and destination workloads.

Proposed change
===============

Implement a Fuel plugin that will install and configure Calico networking in a
Mirantis OpenStack deployment.

Alternatives
------------

N/A - the aim is to implement a Fuel plugin.

Data model impact
-----------------

None.

REST API impact
---------------

None.

Upgrade impact
--------------

When upgrading the Fuel Master node to Fuel Version higher than 6.1, plugin 
compatibility should be checked, and a new plugin installed if necessary.

Security impact
---------------

None.

Notifications impact
--------------------

None.

Other end user impact
---------------------

Once the plugin is installed, the user can enable Calico networking on the
Settings tab of the Fuel Web UI, and customize the network settings.

Performance Impact
------------------

None.

Plugin impact
-------------

None.

Other deployer impact
---------------------

None.

Developer impact
----------------

None.

Infrastructure impact
---------------------

None.

Implementation
==============

Assignee(s)
-----------

Primary assignee:
  Emma Gordon <emma@projectcalico.org> (developer)

Other contributors:
  Neil Jerram <neil@projectcalico.org> (developer, reviewer)

Work Items
----------

* Integrate Calico with Fuel 6.1.

* Implement the Calico plugin.

* Test Calico plugin.

* Create the documentation.

Dependencies
============

* Fuel 6.1.

Testing
=======

* Prepare a test plan.

* Test the plugin according to the test plan.

Documentation Impact
====================

* User Guide.

* Test Plan.

* Test Report.

References
==========

* Project Calico wesbite - http://www.projectcalico.org/

* Calico code on GitHub - https://github.com/Metaswitch/calico

* Calico Documentation - http://docs.projectcalico.org/en/latest/index.html

* Subscribe to the Calico Technical Mailing List - 
  http://lists.projectcalico.org/listinfo/calico-tech

* Calico IRC - freenode IRC: #calico
