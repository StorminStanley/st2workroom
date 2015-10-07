class profile::infrastructure {
  $_packages = hiera('system::packages', [])
  $_offline_mode = hiera('system::offline_mode', false)

  include ::ntp
  include ::profile::rsyslog

  package { $_packages:
    ensure => present,
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
