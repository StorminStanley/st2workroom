class profile::hubot {
  include ::hubot

  if $::osfamily == 'Debian' {
    package { 'npm':
      ensure => present,
    }
  }

  file { '/usr/bin/node':
    ensure => symlink,
    target => '/usr/bin/nodejs',
    require => Class['nodejs'],
  }

  Exec<| title == 'Hubot init' |> {
    path => '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin',
  }
}
