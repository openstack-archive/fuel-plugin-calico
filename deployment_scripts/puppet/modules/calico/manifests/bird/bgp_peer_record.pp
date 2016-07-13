define calico::bird::bgp_peer_record (
  $local_ipaddr,
  $remote_ipaddr,
  $local_as_number,
  $remote_as_number,
  $include  = false,
  $ensure   = 'present',
  $template = 'ext',
) {
  include ::calico::params
  $peer_config_path = "/etc/bird/peers/${template}__${name}.conf"
  file { "${peer_config_path}":
    ensure  => $ensure,
    require => File['/etc/bird/peers'],
    before  => File['/etc/bird/bird.conf'],
    notify  => Service['bird'],
    content => template("calico/bird-peer-${template}.conf.erb"),
  }
  if $include {
    file_line {"":
      line      => "include ${peer_config_path};",
      path      => '/etc/bird/bird.conf',
      #after    => undef,
      #ensure   => 'present',
      #match    => undef, # /.*match/
      #multiple => undef, # 'true' or 'false'
      #name     => undef,
      #replace  => true, # 'true' or 'false'
      require   => File['/etc/bird/bird.conf'],
      notify    => Service['bird']
    }
  }
}

# vim: set ts=2 sw=2 et :