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

class calico::etcd (
  $node_name = $::hostname,
  $node_role,
  $bind_host = $::ipaddress,
  $bind_port = '4001',
  $peer_host = $::ipaddress,
  $peer_port = '2380',
  $cluster_nodes = undef,
  $cluster_token = 'fuel-cluster-1'
) {

case $node_role {
  'proxy': {
      $etcd_cmd_opts = "--proxy on \
--initial-cluster=${cluster_nodes} \
>>/var/log/etcd.log 2>&1"
  }
  'server': {
      $etcd_cmd_opts = "--name=${node_name} \
--advertise-client-urls=http://${bind_host}:${bind_port} \
--listen-client-urls=http://127.0.0.1:${bind_port},http://${bind_host}:${bind_port} \
--listen-peer-urls=http://127.0.0.1:${peer_port},http://${peer_host}:${peer_port} \
--initial-cluster-token='${cluster_token}' \
--initial-cluster=${cluster_nodes} \
--initial-cluster-state=new \
--initial-advertise-peer-urls=http://${peer_host}:${peer_port} \
>>/var/log/etcd.log 2>&1"
  }
  default: {
  }
}

  tweaks::ubuntu_service_override { 'etcd':
    package_name => 'etcd',
  }

  package { ['etcd','python-etcd']:
    ensure => installed,
  } ->

  file { '/var/log/etcd.log':
    ensure => present,
    mode   => '0644',
    owner  => 'etcd',
    group  => 'etcd',
  } ->

  file { '/etc/init/etcd.conf':
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('calico/etcd.conf.erb'),
  } ~>

  service { 'etcd':
    ensure   => 'running',
    enable   => true,
    provider => 'upstart'
  }

}
# vim: set ts=2 sw=2 et :
