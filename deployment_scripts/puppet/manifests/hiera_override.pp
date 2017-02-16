# Manifest that creates hiera config overrride
notice('MODULAR: calico/hiera_override.pp')

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash($plugin_name, {})
$network_scheme  = hiera_hash('network_scheme', {})

# Mangle network_scheme for setup new gateway
if $plugin_settings['metadata']['enabled'] {
  if $plugin_settings['network_name'] == 'another' {
    $network_name = $plugin_settings['another_network_name']
  } else {
    $network_name = $plugin_settings['network_name']
  }
  $overrides = remove_ovs_usage($network_scheme)
  file {"/etc/hiera/plugins/${plugin_name}.yaml":
    ensure  => file,
    content => inline_template('<%= @overrides %>')
  }
}
# vim: set ts=2 sw=2 et :
