#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

class calico::params {

  # Network
  $network_scheme   = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  # current node params
  $node = hiera('node')
  $roles = hiera('roles')
  $mgmt_ip = get_network_role_property('mgmt/vip', 'ipaddr')

  # computes
  $compute_nodes = get_nodes_hash_by_roles($network_metadata, ['compute'])
  $compute_nodes_count = size($compute_nodes)

  # etcd nodes
  $etcd_nodes = get_nodes_hash_by_roles($network_metadata, ['calico-etcd'])
  $etcd_nodes_map = get_node_to_ipaddr_map_by_network_role($etcd_nodes, 'mgmt/vip')
  $etcd_nodes_ips = ipsort(values($etcd_nodes_map))

  # etcd daemon settings
  $etcd_port = '4001'
  $etcd_peer_port = '2380'
  $etcd_servers = suffix(prefix($etcd_nodes_ips, 'http://'), ":${etcd_port}")
  $etcd_servers_list = join($etcd_servers, ',')
  $etcd_servers_named_list = join(suffix(join_keys_to_values($etcd_nodes_map,"=http://"), ":${etcd_peer_port}"), ',')
}
# vim: set ts=2 sw=2 et :