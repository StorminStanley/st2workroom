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

  # A few emerg data points are managed in a template, that is
  # controlled via a fact.
  # https://github.com/saz/puppet-rsyslog/blob/master/lib/facter/rsyslog_version.rb
  # Because this is a masterless installation of Puppet, we do not have
  # PluginSync available to us, so we need to manually mock in the
  # necessary changes that are affecting startup.

  # Template: https://github.com/saz/puppet-rsyslog/blob/master/templates/rsyslog.conf.erb#L72
  file_line { 'rsync global emergency logging for > 7.x':
    path   => '/etc/rsyslog.conf',
    match  => '^\*\.emerg',
    line   => '*.emerg     :omusrmsg:*',
    notify => Service['rsyslog'],
  }

  # Template: https://github.com/saz/puppet-rsyslog/blob/1060bb12493b46239250619688d7e3cbd7212143/templates/client/local.conf.erb#L87
  file_line { 'rsync local client emergency logging for > 7.x':
    path   => '/etc/rsyslog.d/client.conf',
    match  => '^\*\.emerg',
    line   => '*.emerg     :omusrmsg:*',
    notify => Service['rsyslog'],
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
