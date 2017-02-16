notice('MODULAR: calico/neutron_server_config.pp')

# stub for task-based deployment
class neutron { }
class { 'neutron' : }

$network_scheme = hiera_hash('network_scheme', {})
prepare_network_config($network_scheme)
$network_metadata = hiera_hash('network_metadata', {})

include ::calico

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash($plugin_name, {})

# override neutron options
$override_configuration = hiera_hash('configuration', {})
override_resources { 'neutron_api_config':
  data => $override_configuration['neutron_api_config']
} ~> Service['neutron-server']
override_resources { 'neutron_config':
  data => $override_configuration['neutron_config']
} ~> Service['neutron-server']
override_resources { 'neutron_plugin_ml2':
  data => $override_configuration['neutron_plugin_ml2']
} ~> Service['neutron-server']

$neutron_config          = hiera_hash('neutron_config')
$neutron_server_enable   = pick($neutron_config['neutron_server_enable'], true)
$database_vip            = hiera('database_vip')
$management_vip          = hiera('management_vip')
$service_endpoint        = hiera('service_endpoint', $management_vip)
$nova_endpoint           = hiera('nova_endpoint', $management_vip)
$nova_hash               = hiera_hash('nova', { })

$neutron_primary_controller_roles = hiera('neutron_primary_controller_roles', ['primary-controller'])
$neutron_compute_roles            = hiera('neutron_compute_nodes', ['compute'])
$primary_controller               = roles_include($neutron_primary_controller_roles)
$compute                          = roles_include($neutron_compute_roles)

$db_type     = 'mysql'
$db_password = $neutron_config['database']['passwd']
$db_user     = try_get_value($neutron_config, 'database/user', 'neutron')
$db_name     = try_get_value($neutron_config, 'database/name', 'neutron')
$db_host     = try_get_value($neutron_config, 'database/host', $database_vip)
# LP#1526938 - python-mysqldb supports this, python-pymysql does not
if $::os_package_type == 'debian' {
  $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
} else {
  $extra_params = { 'charset' => 'utf8' }
}
$db_connection = os_database_connection({
  'dialect'  => $db_type,
  'host'     => $db_host,
  'database' => $db_name,
  'username' => $db_user,
  'password' => $db_password,
  'extra'    => $extra_params
})

$password                = $neutron_config['keystone']['admin_password']
$username                = pick($neutron_config['keystone']['admin_user'], 'neutron')
$project_name            = pick($neutron_config['keystone']['admin_tenant'], 'services')
$region_name             = hiera('region', 'RegionOne')
$auth_endpoint_type      = 'internalURL'

$ssl_hash                = hiera_hash('use_ssl', {})

$internal_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
$internal_auth_endpoint  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])

$admin_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
$admin_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

$nova_internal_protocol  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
$nova_internal_endpoint  = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$nova_endpoint])

$auth_api_version        = 'v2.0'
$auth_uri                = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"
$auth_url                = "${internal_auth_protocol}://${internal_auth_endpoint}:35357/"
$nova_admin_auth_url     = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/"
$nova_url                = "${nova_internal_protocol}://${nova_internal_endpoint}:8774/v2"

$workers_max             = hiera('workers_max', 16)
$service_workers         = pick($neutron_config['workers'], min(max($::processorcount, 1), $workers_max))

$neutron_advanced_config = hiera_hash('neutron_advanced_configuration', { })
$enable_qos              = pick($neutron_advanced_config['neutron_qos'], false)

if $enable_qos {
  $qos_notification_drivers = 'message_queue'
  $extension_drivers = ['port_security', 'qos']
} else {
  $qos_notification_drivers = undef
  $extension_drivers = ['port_security']
}

$nova_auth_user          = pick($nova_hash['user'], 'nova')
$nova_auth_password      = $nova_hash['user_password']
$nova_auth_tenant        = pick($nova_hash['tenant'], 'services')

$net_role_property     = 'neutron/mesh'
$iface                 = get_network_role_property($net_role_property, 'phys_dev')
$physical_net_mtu      = pick(get_transformation_property('mtu', $iface[0]), '1500')

Package['neutron'] ~>
package { 'calico-control':
  ensure => 'installed',
}
Package['calico-control'] -> Class['::neutron::server']
Package['calico-control'] -> Class['::neutron::plugins::ml2']

class { '::neutron::plugins::ml2':
  type_drivers          => ['local', 'flat'],
  tenant_network_types  => 'local',
  mechanism_drivers     => ['calico'],
  flat_networks         => ['*'],
  #network_vlan_ranges       => $network_vlan_ranges,
  #tunnel_id_ranges          => [],
  #vxlan_group               => $vxlan_group,
  #vni_ranges                => $tunnel_id_ranges,
  path_mtu              => $physical_net_mtu,
  extension_drivers     => $extension_drivers,
  #supported_pci_vendor_devs => $pci_vendor_devs,
  sriov_agent_required  => false,
  enable_security_group => true,
  firewall_driver       => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
}

class { '::neutron::server':
  sync_db                          => $primary_controller,

  username                         => $username,
  password                         => $password,
  project_name                     => $project_name,
  region_name                      => $region_name,
  auth_url                         => $auth_url,
  auth_uri                         => $auth_uri,

  database_connection              => $db_connection,
  database_max_retries             => hiera('max_retries'),
  database_idle_timeout            => hiera('idle_timeout'),
  database_max_pool_size           => hiera('max_pool_size'),
  database_max_overflow            => hiera('max_overflow'),
  database_retry_interval          => '2',

  agent_down_time                  => 60, # it's a requirements of calico-plugin
  allow_automatic_l3agent_failover => false,
  l3_ha                            => false,

  api_workers                      => 0, # it's a requirements of
  rpc_workers                      => 0, # calico-plugin

  router_distributed               => false,
  qos_notification_drivers         => $qos_notification_drivers,
  enabled                          => true,
  manage_service                   => true,
}

Package['neutron'] ~>
augeas { 'dhcp_agents_per_network':
  #context => "/files/etc/neutron/neutron.conf",
  incl    => '/etc/neutron/neutron.conf',
  lens    => 'Puppet.lns',
  changes => [
    "set DEFAULT/dhcp_agents_per_network ${calico::params::compute_nodes_count}",
  ],
} ~> Service['neutron-server']

include ::neutron::params
$neutron_server_package = $neutron::params::server_package ? {
  false   => $neutron::params::package_name,
  default => $neutron::params::server_package,
}

tweaks::ubuntu_service_override { $::neutron::params::server_service:
  package_name => $neutron_server_package,
}

class { '::neutron::server::notifications':
  nova_url     => $nova_url,
  auth_url     => $nova_admin_auth_url,
  username     => $nova_auth_user,
  project_name => $nova_auth_tenant,
  password     => $nova_auth_password,
  region_name  => $region_name,
}

# Stub for Nuetron package
package { 'neutron':
  ensure => 'installed',
  name   => 'binutils',
}
