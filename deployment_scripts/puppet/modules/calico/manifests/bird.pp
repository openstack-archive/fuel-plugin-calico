#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

class calico::bird (
  $template,
  $src_addr,
  $as_number   = '64511',
  $enable_ipv4 = true,
  $enable_ipv6 = false,
  $rr_clients  = {},
  $rr_servers  = {},
  $ext_peers   = {},
) {

  include ::calico

  tweaks::ubuntu_service_override { 'bird':
    package_name => 'bird',
  }

  tweaks::ubuntu_service_override { 'bird6':
    package_name => 'bird',
  }

  package { 'bird':
    ensure => installed,
  } ->
  file { '/etc/bird':
    ensure => directory,
  } ->
  file { '/etc/bird/peers':
    ensure => directory,
  } ->
  file { '/etc/bird/custom.conf':
    ensure => present,
  } ->
  file { '/etc/bird/calico_os_filters.conf':
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('calico/bird-calico_os-filters.conf.erb'),
  } ->
  file { '/etc/bird/bird.conf':
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("calico/bird-${template}.conf.erb"),
  }

  # generate peer-config-files
  generate_bgp_peers(convert_internal_peers($rr_servers, $as_number), 'rr', $src_addr, $as_number)
  generate_bgp_peers(convert_internal_peers($rr_clients, $as_number), 'compute', $src_addr, $as_number)
  generate_bgp_peers($ext_peers, 'ext', $src_addr, $as_number)

  if $enable_ipv4 {
    Package['bird'] ~>
    service { 'bird':
      ensure     => running,
      enable     => true,
      hasrestart => false,
      restart    => '/usr/sbin/birdc configure'
    }
    File['/etc/bird/calico_os_filters.conf'] ~> Service['bird']
    File['/etc/bird/custom.conf'] ~> Service['bird']
    File['/etc/bird/bird.conf'] ~> Service['bird']
  }

  if $enable_ipv6 {
    Package['bird'] ~>
    service { 'bird6':
      ensure     => running,
      enable     => true,
      hasrestart => false,
      restart    => '/usr/sbin/birdc6 configure'
    }
    File['/etc/bird/calico_os_filters.conf'] ~> Service['bird6']
    File['/etc/bird/custom.conf'] ~> Service['bird6']
    File['/etc/bird/bird6.conf'] ~> Service['bird6']
  }

}
# vim: set ts=2 sw=2 et :
