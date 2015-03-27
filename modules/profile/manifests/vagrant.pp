class profile::vagrant {
  $packages = ['avahi-daemon', 'ruby-dev']
  package { $packages:
    ensure => present,
  }
}
