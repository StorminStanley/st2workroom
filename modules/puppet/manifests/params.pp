class puppet::params {

  # OS Init Type Detection
  # This block of code is used to detect the underlying Init Daemon
  # automatically.  This code is based on
  # https://github.com/jethrocarr/puppet-initfact/blob/master/lib/facter/initsystem.rb
  # This is Puppet code because masterless puppet has issues with pluginsync,
  # so we need a way to determine what the init system.
  case $::osfamily {
    'RedHat': {
      if $::operatingsystem == 'Amazon' {
        $init_type = $::operatingsystemmajrelease ? {
          '2014'  => 'sysv',
          '2015'  => 'sysv',
          default => 'sysv',
        }
      } else {
        $init_type = $::operatingsystemmajrelease ? {
          '5'     => 'sysv',
          '6'     => 'sysv',
          default => 'systemd',
        }
      }
    }
    'Debian': {
      if $::operatingsystem == 'Debian' {
        $init_type = $::operatingsystemmajrelease ? {
          '6'     => 'sysv',
          '7'     => 'sysv',
          '8'     => 'systemd',
          default => 'systemd',
        }
      } elsif $::operatingsystem == 'Ubuntu' {
        $init_type = $::operatingsystemmajrelease ? {
          '12.04' => 'upstart',
          '14.04' => 'upstart',
          '14.10' => 'upstart',
          '15.04' => 'systemd',
          default => 'systemd',
        }
      }
    }
    default: {
      $init_type = undef
    }
  }
}
