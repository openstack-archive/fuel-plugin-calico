#!/bin/bash
# This script removes default network config created in OpenStack as part of a
# Fuel deployment. These networks do not work for instance creation with
# Calico, so need to be removed.

# OpenStack authentication and authorization requires environment variables
# contained in the openrc file, this will allow us to issue commands via the 
# neutron API.
source /root/openrc

# Details of the default networks/routers created on Fuel deployment of a
# Mirantis OpenStack environment.
DEFAULT_NET=net04
DEFAULT_NET_EXT=net04_ext
DEFAULT_ROUTER=router04

# DEFAULT_NET_EXT is set as the gateway for DEFAULT_ROUTER, we must clear that
# before we can delete the network.
neutron router-gateway-clear $DEFAULT_ROUTER
neutron net-delete $DEFAULT_NET_EXT

# DEFAULT_NET cannot be deleted until all ports configured on the network have 
# been removed. We get details of the configured ports from the "neutron port-list"
# command, whose output is of the form:
# +-----+------+-------------------+-----------------------------------------------+
# | id  | name | mac_address       | fixed_ips                                     |
# +-----+------+-------------------+-----------------------------------------------+
# | foo |      | fa:16:3e:ae:70:4e | {"subnet_id": "bar", "ip_address": "a.b.c.d"} |
# +-----+------+-------------------+-----------------------------------------------+
port_ids=$(neutron port-list | grep "|" | grep -v "fixed_ips" | cut -d " " -f 2)
for port_id in "${port_ids[@]}"
do
  neutron port-delete $port_id
  if [[ $? != 0 ]]; then
    # One of the ports is associated with the interface for the default router.
    # This causes port deletion to fail. So we delete the interface on the
    # router (this also removes the port).
    neutron router-interface-delete $DEFAULT_ROUTER port=$port_id
  fi
done

# We can now delete the default router and the default network.
neutron router-delete $DEFAULT_ROUTER
neutron net-delete $DEFAULT_NET

