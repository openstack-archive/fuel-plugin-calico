notice('MODULAR: calico/private_gateway_check.pp')

$network_scheme = hiera_hash('network_scheme')
prepare_network_config($network_scheme)
$calico_alt_gateway_br = get_network_role_property('neutron/mesh','interface')
$calico_alt_gateway    = try_get_value($network_scheme,"endpoints/${calico_alt_gateway_br}/vendor_specific/provider_gateway")

if ! is_ip_address($calico_alt_gateway) {
  fail("Gateway for Private network does not specified or wrong !!!")
}

# vim: set ts=2 sw=2 et :