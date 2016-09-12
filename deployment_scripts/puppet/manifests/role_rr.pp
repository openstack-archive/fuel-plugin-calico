notice('MODULAR: calico/rr_bird.pp')

prepare_network_config(hiera_hash('network_scheme'))
$network_metadata = hiera_hash('network_metadata', {})


# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash("${plugin_name}", {})
$enable_ipv4 = try_get_value($plugin_settings, 'enable_ipv4', true)
$enable_ipv6 = try_get_value($plugin_settings, 'enable_ipv6', false)
$as_number   = try_get_value($plugin_settings, 'as_number', 65001)
if try_get_value($plugin_settings, 'enable_external_peering', false) {
  $ext_peers = convert_external_peers(try_get_value($plugin_settings, 'external_peers', ''))
} else {
  $ext_peers = {}
}

$local_ip = get_network_role_property('neutron/mesh', 'ipaddr')

$compute_nodes = get_nodes_hash_by_roles($network_metadata, ['compute'])
$compute_nodes_ip = get_node_to_ipaddr_map_by_network_role($compute_nodes, 'neutron/mesh')

# Firewall initials
class { '::firewall':}
Class['::firewall'] -> Firewall<||>
Class['::firewall'] -> Firewallchain<||>

firewall { '410 bird':
  dport  => '179',
  proto  => 'tcp',
  action => 'accept',
} ->
class { 'calico::bird':
  template    => 'rr',
  as_number   => $as_number,
  enable_ipv4 => $enable_ipv4,
  enable_ipv6 => $enable_ipv6,
  src_addr    => $local_ip,
  rr_clients  => $compute_nodes_ip,
  rr_servers  => {},
  ext_peers   => $ext_peers,
}
