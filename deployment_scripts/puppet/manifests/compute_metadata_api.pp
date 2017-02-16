notice('MODULAR: calico/compute_metadata_api.pp')

# $network_scheme = hiera_hash('network_scheme', {})
# prepare_network_config($network_scheme)
# $network_metadata = hiera_hash('network_metadata', {})

package { 'nova-api-metadata':
  ensure => 'installed',
  name   => 'nova-api-metadata',
} ->
service { 'nova-api-metadata':
  ensure => running,
  enable => true,
}

# Package['nova-api-metadata'] -> Nova_config<||>
# tweaks::ubuntu_service_override { 'nova-api-metadata':
#   package_name => 'nova-api-metadata'
# }
# Nova_config<||> -> Service['nova-api-metadata']
