class profile::infrastructure {
  $_packages = hiera('system::packages', [])
  $_offline_mode = hiera('system::offline_mode', false)
  $_fqdn = hiera('system::hostname', $::fqdn)
  $_host_ip = hiera('system::ipaddress', $::ipaddress_eth0)
  $_http_proxy = hiera('system::http_proxy', undef)
  $_https_proxy = hiera('system::https_proxy', undef)

  include ::ntp
  include ::profile::rsyslog

  package { $_packages:
    ensure => present,
  }

  # Setup Hostname via Hiera
  ## This is a bit of a Snake eating its own tail here, but
  ## Allows us to set up a random hostname (say, with a cloud provider),
  ## and then let the user come around and configure it with st2installer

  class { '::hostname':
    hostname => $_fqdn,
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

  file_line { 'disable_tty':
    path  => '/etc/sudoers',
    match => '^Defaults\s+requiretty',
    line  => '## Defaults    requiretty',
  }

  # Disable SELinux on RedHat Hosts
  if $::osfamily == 'RedHat' {
    class { '::selinux':
      mode => 'permissive',
    }
  }

  # Setup HTTP / HTTPS proxies
  if $_http_proxy {
    file_line { 'System HTTP Proxy':
      path  => '/etc/environment',
      match => '^HTTP_PROXY=',
      line  => "HTTP_PROXY=${_http_proxy}",
    }
  }
  if $_https_proxy {
    file_line { 'System HTTPS Proxy':
      path  => '/etc/environment',
      match => '^HTTPS_PROXY=',
      line  => "HTTPS_PROXY=${_https_proxy}",
    }
  }
}
