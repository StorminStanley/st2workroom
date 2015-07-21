class profile::vagrant {
  $_packages = $::osfamily ? {
    'Debian' => ['avahi-daemon', 'vim', 'software-properties-common', 'zsh'],
    'RedHat' => ['avahi'],
  }

  package { $_packages:
    ensure => present,
  }

  service { 'avahi-daemon':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  sudo::conf { 'vagrant':
    ensure  => present,
    content => '%vagrant ALL=(ALL) NOPASSWD: ALL',
  }
}
