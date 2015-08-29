class profile::infrastructure {
  $_hostname = hiera('system::hostname', $::hostname)
  $_host_ip = hiera('system::ipaddress', $::ipaddress)
  $_packages = hiera('system::packages', [])
  include ::ntp
  include ::profile::rsyslog

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

  # Manage the entire /etc/hosts
  # This is needed to ensure no dangling left-over host entries.
  resources { 'host':
    purge => true,
  }
  host { 'default v4 localhost':
    ensure       => present,
    name         => 'localhost.localdomain',
    ip           => '127.0.0.1',
    host_aliases => 'localhost',
  }
  host { 'default hostname v4':
    ensure       => present,
    name         => $_hostname,
    ip           => $_host_ip,
    host_aliases => $::fqdn,
  }
}
