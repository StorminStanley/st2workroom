class profile::vagrant {
  package { 'avahi-daemon':
    ensure => present,
  }
}
