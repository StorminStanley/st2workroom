class profile::rsyslog {
  class { '::rsyslog::client':
    custom_config => 'profile/rsyslog/client.conf.erb',
  }

  $_rsyslog_settings = '$ModLoad imudp
  $UDPServerRun 514
  $ModLoad imtcp
  $InputTCPServerRun 515'

  file { '/etc/rsyslog.d/server.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => $_rsyslog_settings,
    notify  => Class['::rsyslog::service'],
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
