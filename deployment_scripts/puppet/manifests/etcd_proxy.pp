notice('MODULAR: calico/etcd_proxy.pp')

prepare_network_config(hiera_hash('network_scheme'))
$network_metadata = hiera_hash('network_metadata', {})

include ::calico

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash($plugin_name, {})

# Firewall initials
class { '::firewall':}
Class['::firewall'] -> Firewall<||>
Class['::firewall'] -> Firewallchain<||>

firewall { '400 etcd':
  dport  => [
    $calico::params::etcd_port
  ],
  proto  => 'tcp',
  action => 'accept',
} ->
# Deploy etcd cluster member
class { '::calico::etcd':
  node_role     => 'proxy',
  bind_host     => $calico::params::mgmt_ip,
  bind_port     => $calico::params::etcd_port,
  cluster_nodes => $calico::params::etcd_servers_named_list,
}
