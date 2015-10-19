class profile::rsyslog {
  include ::rsyslog::client

  file_line{'$ModLoad imudp':
    path   => '/etc/rsyslog.conf',
    line   => '$ModLoad imudp',
    match  => '^\$ModLoad imudp',
    notify => Service['rsyslog']
  }
  file_line{'$UDPServerRun 514':
    path   => '/etc/rsyslog.conf',
    line   => '$UDPServerRun 514',
    match  => '^\$UDPServerRun',
    notify => Service['rsyslog']
  }

  # Note: We also listen on TCP so long messages are not truncated
  file_line{'$ModLoad imtcp':
    path   => '/etc/rsyslog.conf',
    line   => '$ModLoad imtcp',
    match  => '^\$ModLoad imtcp',
    notify => Service['rsyslog']
  }
  file_line{'$InputTCPServerRun 515':
    path   => '/etc/rsyslog.conf',
    match  => '^\$InputTCPServerRun',
    line   => '$InputTCPServerRun 515',
    notify => Service['rsyslog']
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
