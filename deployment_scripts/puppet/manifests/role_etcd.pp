notice('MODULAR: calico/etcd.pp')

prepare_network_config(hiera_hash('network_scheme'))
$network_metadata = hiera_hash('network_metadata', {})

include calico

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash("${plugin_name}", {})
$cluster_info    = hiera_hash('cluster', {})
$cluster_token   = try_get_value($cluster_info, 'name', 'openstack-calico-cluster')

# Firewall initials
class { '::firewall':}
Class['::firewall'] -> Firewall<||>
Class['::firewall'] -> Firewallchain<||>

firewall { '400 etcd':
  dport  => [
    $calico::params::etcd_port,
    $calico::params::etcd_peer_port
  ],
  proto  => 'tcp',
  action => 'accept',
} ->
# Deploy etcd cluster member
class { 'calico::etcd':
  node_role     => 'server',
  bind_host     => $calico::params::mgmt_ip,
  bind_port     => $calico::params::etcd_port,
  peer_host     => $calico::params::mgmt_ip,
  peer_port     => $calico::params::etcd_peer_port,
  cluster_nodes => $calico::params::etcd_servers_named_list,
  cluster_token => $cluster_token
}
