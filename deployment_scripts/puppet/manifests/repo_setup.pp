notice('MODULAR: calico/repo_setup.pp')

# Initial constants
$plugin_name     = 'fuel-plugin-calico'
$plugin_settings = hiera_hash($plugin_name, {})

# Bird PPA
apt::source { 'bird-repo':
  location => 'http://ppa.launchpad.net/cz.nic-labs/bird/ubuntu',
  repos    => 'main',
  #release  => 'trusty',
  include  => {
    'src' => false,
  },
}

# Calico PPA
apt::source { 'calico-repo':
  #location => "http://ppa.launchpad.net/project-calico/stable/ubuntu",
  location => 'http://ppa.launchpad.net/project-calico/calico-1.4/ubuntu',
  repos    => 'main',
  #release  => 'trusty',
  include  => {
    'src' => false,
  },
}

Apt::Source<||> ~> Exec<| title == 'apt_update' |>
Exec<| title == 'apt_update' |> -> Package<||>
