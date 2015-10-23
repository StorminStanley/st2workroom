class profile::rsyslog {
  class { '::rsyslog::client':
    custom_config => 'profile/rsyslog/client.conf.erb',
  }

  # Ensure latest version of rsyslogd is available for RHEL 6 systems
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    wget::fetch { 'rsyslogd repo':
      source      => 'http://rpms.adiscon.com/rsyslogall.repo',
      cache_dir   => '/var/cache/wget',
      destination => '/etc/yum.repos.d/rsyslogall.repo',
      before      => Class['::rsyslog::client'],
    }
  }
}
