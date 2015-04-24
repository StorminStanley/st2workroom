class profile::vagrant {
  $_packages = $::osfamily ? {
    'Debian' => ['avahi-daemon', 'ruby-dev'],
    'RedHat' => ['avahi', 'ruby-devel'],
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
}
