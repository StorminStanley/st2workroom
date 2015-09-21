class profile::rsyslog {
  include ::rsyslog::client

  file_line{'$ModLoad imudp':
    path => '/etc/rsyslog.conf',
    line => '$ModLoad imudp'
  }
  file_line{'$UDPServerRun 514':
    path => '/etc/rsyslog.conf',
    line => '$UDPServerRun 514'
  }
}
