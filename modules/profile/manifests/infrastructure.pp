class profile::infrastructure {
  $_packages = hiera('system::packages', [])
  $_offline_mode = hiera('system::offline_mode', false)
  $_fqdn = hiera('system::hostname', $::fqdn)
  $_host_ip = hiera('system::ipaddress', $::ipaddress_eth0)

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
    content => "${_fqdn}\n",
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
    name         => $_fqdn,
    ip           => $_host_ip,
    host_aliases => $::hostname,
  }

  # Set offline State
  ## Various helper applications to the workroom require
  ## knowledge if the node is purposely in offline-mode
  ## in order to decide whether or not to make calls to
  ## the internet.
  ##
  ## To do this, we set a fact about the system that
  ## can be referenced.
  facter::fact { 'system_offline_mode':
    value => $_offline_mode,
  }
}
