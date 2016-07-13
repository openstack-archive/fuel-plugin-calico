notice('MODULAR: calico/neutron-br-int-workaround.pp')

$use_ovs = hiera('use_ovs', false)

if $use_ovs {
  exec {'workaround__create_br-int':
    command   => 'ovs-vsctl --may-exist add-br br-int',
    path      => ['/usr/bin', '/usr/sbin'],
    try_sleep => 6,
    tries     => 10,
  }
}
