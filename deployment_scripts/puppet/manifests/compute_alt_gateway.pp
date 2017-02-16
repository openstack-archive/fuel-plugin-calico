notice('MODULAR: calico/compute_alt_gateway.pp')

$network_scheme = hiera_hash('network_scheme')
prepare_network_config($network_scheme)
$network_metadata = hiera_hash('network_metadata', {})

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$calico_mark = '0xCA'

$neutron_config   = hiera_hash('neutron_config')
$private_net_name = try_get_value($neutron_config, 'default_private_net', 'admin_internal_net')
$neutron_networks = try_get_value($neutron_config, 'predefined_networks', {})
$private_net      = try_get_value($neutron_networks, $private_net_name, {'L3'=>{}})
$subnet_cidr      = pick($private_net['L3']['subnet'], '10.20.0.0/16')

$calico_alt_gateway_br = get_network_role_property('neutron/mesh','interface')
$calico_alt_gateway    = try_get_value($network_scheme,"endpoints/${calico_alt_gateway_br}/vendor_specific/provider_gateway")

# Firewall initials
class { '::firewall':}
Class['::firewall'] -> Firewall<||>
Class['::firewall'] -> Firewallchain<||>

# iptables -t mangle -N calico-alt-gw-MARK
firewallchain { 'calico-alt-gw-MARK:mangle:IPv4':
  ensure  => present,
}->
# iptables -t mangle -A PREROUTING -i tap+ -j calico-alt-gw-MARK
firewall { '010 process traffic from VM instances to outside':
  ensure  => present,
  table   => 'mangle',
  chain   => 'PREROUTING',
  iniface => 'tap+',
  proto   => 'all',
  jump    => 'calico-alt-gw-MARK',
} ->
#iptables -t mangle -A calico-alt-gw-MARK -d 192.168.111.0/24 -j RETURN
firewall { '011 skip internal traffic':
  ensure      => present,
  table       => 'mangle',
  chain       => 'calico-alt-gw-MARK',
  destination => $subnet_cidr,
  proto       => 'all',
  jump        => 'RETURN',
} ->
#iptables -t mangle -A calico-alt-gw-MARK -j MARK --set-mark 0x222
firewall { '012 mark traffic from VM instances to outside':
  ensure   => present,
  table    => 'mangle',
  chain    => 'calico-alt-gw-MARK',
  jump     => 'MARK',
  proto    => 'all',
  set_mark => $calico_mark
}

file { '/etc/init/calico-alt-gateway.conf':
  ensure  => present,
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => template('calico/calico-alt-gateway.conf.erb'),
} ~>
service {'calico-alt-gateway':
  ensure     => running,
  enable     => true,
  hasrestart => false,
}

# Without such settings source-routing works wrong. For more details
# read the https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
# Value '2' may be better, but Calico Felix agent is not compotible with '2'
sysctl::value {
  'net.ipv4.conf.all.rp_filter':                      value => '0';
  "net.ipv4.conf.${calico_alt_gateway_br}.rp_filter": value => '0';
}

# vim: set ts=2 sw=2 et :
