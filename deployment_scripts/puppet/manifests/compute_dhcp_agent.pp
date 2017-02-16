notice('MODULAR: calico/compute_dhcp_agent.pp')

# stub for task-based deployment
# class neutron { }
# class { 'neutron' : }

$debug                   = hiera('debug', true)
$resync_interval         = '30'

# class { '::neutron::agents::dhcp':
#   debug                    => $debug,
#   resync_interval          => $resync_interval,
#   manage_service           => false,
#   enable_isolated_metadata => true,
#   enabled                  => false,
# }

# # stub package for 'neutron::agents::dhcp' class
# package { 'neutron':
#   name   => 'binutils',
#   ensure => 'installed',
# }

package { 'neutron-dhcp-agent':
  ensure => 'installed',
} ->
service { 'neutron-dhcp-agent':
  ensure => 'stopped',
  enable => false
}
tweaks::ubuntu_service_override { 'neutron-dhcp-agent':
  package_name => 'neutron-dhcp-agent',
}

Package['neutron-dhcp-agent'] ->
package { 'calico-dhcp-agent':
  ensure => 'installed',
} ->
service { 'calico-dhcp-agent':
  ensure => 'running',
  enable => true
}
tweaks::ubuntu_service_override { 'calico-dhcp-agent':
  package_name => 'calico-dhcp-agent',
}

neutron_config { 'DEFAULT/use_namespaces': value => false }

Neutron_config<||> ~> Service['calico-dhcp-agent']
Neutron_dhcp_agent_config<||> ~> Service['calico-dhcp-agent']
