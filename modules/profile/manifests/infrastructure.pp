class profile::infrastructure {
  $_hostname = hiera('system::hostname', $::fqdn)
  $_packages = hiera('system::packages', [])
  include ::ntp

  package { $_packages:
    ensure => present,
  }

  # Setup Hostname via Hiera
  ## This is a bit of a Snake eating its own tail here, but
  ## Allows us to set up a random hostname (say, with a cloud provider),
  ## and then let the user come around and configure it with st2installer
  file { '/etc/hostname':
    ensure => file,
    content => "${_hostname}\n",
    notify  => Exec['apply hostname'],
  }
  exec { "apply hostname":
    command => "/bin/hostname -F /etc/hostname",
    unless  => "/usr/bin/test `hostname` = `/bin/cat /etc/hostname`",
  }
  host { 'default hostname v4':
    ensure        => present,
    name          => $_hostname,
    host_aliases  => [
      'localhost',
      'localhost.localdomain',
    ],
    ip            => '127.0.0.1',
  }
}
