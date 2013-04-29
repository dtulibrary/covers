include vagrant_hosts

class {'apache2':
  disable_default_vhost => true,
}

class {'gazo': 
  rails_env  => 'staging',
  conf_set   => 'vagrant',
  vhost_name => 'gazo.vagrant.vm',
}
