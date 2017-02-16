notice('MODULAR: calico/neutron_networks.pp')

#include calico

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash($plugin_name, {})

$access_hash = hiera_hash('access', {})
$tenant_name = try_get_value($access_hash, 'tenant', 'admin')

# From docs:
# neutron net-create --shared --provider:network_type local calico
# neutron subnet-create --gateway 10.65.0.1 --enable-dhcp --ip-version 4 --name calico-v4 calico 10.65.0/24

$net = 'calico'
$subnet = 'calico-v4'
$neutron_config   = hiera_hash('neutron_config')
$private_net_name = try_get_value($neutron_config, 'default_private_net', 'admin_internal_net')
$neutron_networks = try_get_value($neutron_config, 'predefined_networks', {})
$private_net      = try_get_value($neutron_networks, $private_net_name, {'L3'=>{}})
$subnet_cidr      = pick($private_net['L3']['subnet'], '10.20.0.0/16')
$subnet_gw        = pick($private_net['L3']['gateway'],  '10.20.0.1')

neutron_network { $net :
  ensure                => 'present',
  provider_network_type => 'local',
  shared                => true,
  tenant_name           => $tenant_name,
} ->
neutron_subnet { $subnet :
  ensure       => 'present',
  cidr         => $subnet_cidr,
  network_name => $net,
  gateway_ip   => $subnet_gw,
  enable_dhcp  => true,
  ip_version   => '4',
  tenant_name  => $tenant_name,
}
