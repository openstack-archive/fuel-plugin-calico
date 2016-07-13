#    Copyright 2015 Mirantis, Inc.
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

  # General configuration
  $settings = hiera('calico-fuel-plugin', {})

  $as_number = $settings['as_number']

  # Calico release
  $calico_release = hiera('openstack_version')? {
    /^liberty/    => 'stable',
    /^mitaka/     => 'unstable',
    default       => '',
  }

  # Network
  $network_scheme   = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  # $iface            = get_network_role_property('ex', 'phys_dev')
  # $physical_net_mtu = pick(get_transformation_property('mtu', $iface[0]), '1500')

  $mgmt_vip   = $network_metadata['vips']['management']['ipaddr']

  # node params
  $node = hiera('node')
  $roles = hiera('roles')
  #$ex_ip = get_network_role_property('ex', 'ipaddr')
  $mgmt_ip = get_network_role_property('mgmt/vip', 'ipaddr')
  $mgmt_interface = get_network_role_property('mgmt/vip', 'interface')
  #$primary_controller = roles_include('primary-controller')

  # # controllers
  # $controller_nodes = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])
  # # mgmt IPs
  # $controller_mgmt_nodes = get_node_to_ipaddr_map_by_network_role($controller_nodes, 'mgmt/vip')
  # $controller_mgmt_ips = ipsort(values($controller_mgmt_nodes))
  # etcd IPs
  $etcd_nodes = get_nodes_hash_by_roles($network_metadata, ['calico-etcd'])
  $etcd_nodes_map = get_node_to_ipaddr_map_by_network_role($etcd_nodes, 'mgmt/vip')
  $etcd_nodes_ips = ipsort(values($etcd_nodes_map))
  # # public IPs
  # $controller_ex_nodes = get_node_to_ipaddr_map_by_network_role($controller_nodes, 'ex')
  # $controller_ex_ips = ipsort(values($controller_ex_nodes))

  # computes
  $compute_nodes = get_nodes_hash_by_roles($network_metadata, ['compute'])
  $compute_nodes_count = size($compute_nodes)

  # public IPs
  # $compute_ex_nodes = get_node_to_ipaddr_map_by_network_role($compute_nodes, 'ex')
  # $compute_ex_ips = ipsort(values($compute_ex_nodes))

  # client peers list
  $client_peers = $compute_ex_ips

  # etcd settings
  $etcd_port = '4001'
  $etcd_peer_port = '2380'
  $etcd_servers = suffix(prefix($etcd_nodes_ips, 'http://'), ":${etcd_port}")
  $etcd_servers_list = join($etcd_servers, ',')
  $etcd_servers_named_list = join(suffix(join_keys_to_values($etcd_nodes_map,"=http://"), ":${etcd_peer_port}"), ',')
}
# vim: set ts=2 sw=2 et :