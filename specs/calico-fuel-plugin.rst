Copyright 2016 Mirantis

Fuel Plugin for Project Calico
==============================

The Calico plugin provides the ability to use Calico as a networking backend
for Mirantis OpenStack.

Compatible with Fuel version 9.0.

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

Re-design the Calico plugin for Fuel version 6.1 to support version 9.0.
This will involve moving from the Juno to the Mitaka release of
Mirantis OpenStack.

Support for HA deployments with multiple controllers will also be added.

Alternatives
------------

N/A

Data model impact
-----------------

None.

REST API impact
---------------

None.

Upgrade impact
--------------

When upgrading the Fuel Master node to Fuel Version higher than 9.0, plugin
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
Wizard while create Openstack Env, and customize the network settings.

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
  Sergey Vasilenko <svasilenko@mirantis.com>

Other contributors:
  Alexander Didenko <adidenko@mirantis.com>
  Oleksandr Martsyniuk <omartsyniuk@mirantis.com>

Work Items
----------

* Integrate Calico with Fuel 9.0.

* Update the Calico plugin.

* Test Calico plugin.

* Create the documentation.

Dependencies
============

* Fuel 9.0.

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

* Calico code on GitHub - https://github.com/projectcalico/calico

* Calico Documentation - http://docs.projectcalico.org/en/latest/index.html

* Calico IRC - freenode IRC: #calico
