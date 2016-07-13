notice('MODULAR: calico/compute_felix.pp')

include calico

# required, because neutron-dhcp-agent one of dependency of calico-compute
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

package { 'calico-felix':
  ensure => 'installed',
} ->
package { 'calico-compute':
  ensure => 'installed',
} ->
service { 'calico-felix':
  ensure => 'running',
  enable => true
}
tweaks::ubuntu_service_override { 'calico-felix':
  package_name => 'calico-felix',
}

$etcd_host = '127.0.0.1'
$etcd_port = $calico::params::etcd_port
$metadata_host = '127.0.0.1'
$metadata_port = 8775

Package['calico-felix'] ->
file { '/etc/calico/felix.cfg':
  ensure  => present,
  content => template('calico/felix.cfg.erb'),
} ~>
Service['calico-felix']