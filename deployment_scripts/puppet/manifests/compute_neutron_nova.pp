notice('MODULAR: calico/compute_neutron_nova.pp')

$network_scheme = hiera_hash('network_scheme', {})
prepare_network_config($network_scheme)
$network_metadata = hiera_hash('network_metadata', {})

include calico
include ::nova::params


# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash("${plugin_name}", {})

$neutron_config          = hiera_hash('neutron_config')
$management_vip          = hiera('management_vip')
$service_endpoint        = hiera('service_endpoint', $management_vip)

# # LP#1526938 - python-mysqldb supports this, python-pymysql does not
# if $::os_package_type == 'debian' {
#   $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
# } else {
#   $extra_params = { 'charset' => 'utf8' }
# }

# $net_role_property     = 'neutron/mesh'
# $iface                 = get_network_role_property($net_role_property, 'phys_dev')
# $physical_net_mtu      = pick(get_transformation_property('mtu', $iface[0]), '1500')

$nova_hash                  = hiera_hash('nova', {})
$libvirt_vif_driver         = pick($nova_hash['libvirt_vif_driver'], 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver')

$region_name                = hiera('region', 'RegionOne')
$admin_password             = try_get_value($neutron_config, 'keystone/admin_password')
$admin_tenant_name          = try_get_value($neutron_config, 'keystone/admin_tenant', 'services')
$admin_username             = try_get_value($neutron_config, 'keystone/admin_user', 'neutron')
$auth_api_version           = 'v3'
$ssl_hash                   = hiera_hash('use_ssl', {})

$admin_identity_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_identity_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

$neutron_internal_protocol  = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
$neutron_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', [hiera('neutron_endpoint', ''), $management_vip])

$neutron_auth_url           = "${admin_identity_protocol}://${admin_identity_address}:35357/${auth_api_version}"
$neutron_url                = "${neutron_internal_protocol}://${neutron_internal_endpoint}:9696"

$nova_migration_ip          =  get_network_role_property('nova/migration', 'ipaddr')

service { 'libvirt' :
  ensure   => 'running',
  enable   => true,
  name     => $::nova::params::libvirt_service_name,
  provider => $::nova::params::special_service_provider,
} ->
exec { 'destroy_libvirt_default_network':
  command => 'virsh net-destroy default',
  onlyif  => "virsh net-list | grep -qE '^\s*default\s'",
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  tries   => 3,
} ->
exec { 'undefine_libvirt_default_network':
  command => 'virsh net-undefine default',
  onlyif  => "virsh net-list --all | grep -qE '^\s*default\s'",
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  tries   => 3,
}

Service['libvirt'] ~> Exec['destroy_libvirt_default_network']
Service['libvirt'] ~> Exec['undefine_libvirt_default_network']

# script called by qemu needs to manipulate the tap device
file_line { 'clear_emulator_capabilities':
  path   => '/etc/libvirt/qemu.conf',
  line   => 'clear_emulator_capabilities = 0',
  notify => Service['libvirt']
}

class { '::nova::compute::neutron':
  libvirt_vif_driver => undef,
  force_snat_range   => undef,
}

nova_config {
  'DEFAULT/linuxnet_interface_driver': ensure => absent;
  'DEFAULT/my_ip':                     value => $nova_migration_ip;
}

class { '::nova::network::neutron' :
  neutron_password     => $admin_password,
  neutron_project_name => $admin_tenant_name,
  neutron_region_name  => $region_name,
  neutron_username     => $admin_username,
  neutron_auth_url     => $neutron_auth_url,
  neutron_url          => $neutron_url,
  neutron_ovs_bridge   => '',
}

augeas { 'sysctl-net.bridge.bridge-nf-call-arptables':
  context => '/files/etc/sysctl.conf',
  changes => "set net.bridge.bridge-nf-call-arptables '1'",
  before  => Service['libvirt'],
}
augeas { 'sysctl-net.bridge.bridge-nf-call-iptables':
  context => '/files/etc/sysctl.conf',
  changes => "set net.bridge.bridge-nf-call-iptables '1'",
  before  => Service['libvirt'],
}
augeas { 'sysctl-net.bridge.bridge-nf-call-ip6tables':
  context => '/files/etc/sysctl.conf',
  changes => "set net.bridge.bridge-nf-call-ip6tables '1'",
  before  => Service['libvirt'],
}
