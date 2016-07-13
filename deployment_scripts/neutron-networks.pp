notice('MODULAR: calico/neutron-networks.pp')

$access_hash = hiera_hash('access', {})
$tenant_name = try_get_value($access_hash, 'tenant', 'admin')

# From docs:
# neutron net-create --shared --provider:network_type local calico
# neutron subnet-create --gateway 10.65.0.1 --enable-dhcp --ip-version 4 --name calico-v4 calico 10.65.0/24

# TODO(adidenko): we can pull config info from plugin settings via Hiera
# instead of hardcode
$net = 'calico'
$subnet = 'calico-v4'
$subnet_cidr = '10.65.0.0/24'
$subnet_gw = '10.65.0.1'

neutron_network { $net :
  ensure                => 'present',
  provider_network_type => 'local',
  shared                => true,
  tenant_name           => $tenant_name,
} ->
neutron_subnet { $subnet :
  ensure           => 'present',
  cidr             => $subnet_cidr,
  network_name     => $net,
  gateway_ip       => $subnet_gw,
  enable_dhcp      => true,
  ip_version       => '4',
  tenant_name      => $tenant_name,
}

