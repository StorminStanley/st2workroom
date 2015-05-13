class profile::vagrant {
  $_packages = $::osfamily ? {
    'Debian' => ['avahi-daemon', 'vim', 'software-properties-common'],
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
}
