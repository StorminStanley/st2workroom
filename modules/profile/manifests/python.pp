class profile::python {
  include ::st2::profile::python
  include ::st2::profile::repos

  file { '/etc/facter/facts.d/pip_upgrade_20150902.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'pip_upgrade_20150902=true',
    notify  => Exec['update-pip'],
  }

  exec { 'update-pip':
    command     => 'pip install -U pip',
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    refreshonly => true,
    require     => Class['::st2::profile::repos'],
  }

  Exec['update-pip'] -> Python::Pip<||>
  Class['::st2::profile::repos'] -> Class['::st2::profile::python']

  if $osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
    exec { 'remove-six':
      command     => 'yum remove -y python-six',
      path        => '/usr/sbin:/usr/bin:/sbin:/bin',
      refreshonly => true,
    }

    # Ensure to only try and install a single time, otherwise
    # Skip over to ensure no failures trying to reinstall
    if ! $::six_upgrade_20151012 {
      package {'python-six-1.9.0-1.el7.noarch.rpm':
        ensure    => 'present',
        provider  => 'rpm',
        source    => 'http://cbs.centos.org/kojifiles/packages/python-six/1.9.0/1.el7/noarch/python-six-1.9.0-1.el7.noarch.rpm',
        subscribe => Exec['remove-six'],
        before    => Facter::Fact['six_upgrade_20151012'],
        notify    => Exec['install jsonpath-rw']
      }
    }

    # Set a breadcrumb for future Puppet runs
    facter::fact { 'six_upgrade_20151012':
      value => 'true',
    }
  }

  # RedHad 6 uses Python 2.6 by default, and we are pulling upstream
  # from IUS to provide Python 2.7. The following sets up latest Python
  # to be the System Python
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    alternative_entry {'/usr/bin/python2.7':
      ensure   => present,
      altlink  => '/usr/bin/python',
      altname  => 'python',
      priority => 10,
      require  => Class['::st2::profile::python'],
    }
    alternatives { 'python':
      path    => '/usr/bin/python2.7',
      require => Class['::st2::profile::python'],
    }

    alternative_entry {'/usr/bin/pip2.7':
      ensure   => present,
      altlink  => '/usr/bin/pip',
      altname  => 'pip',
      priority => 10,
      require  => Class['::st2::profile::python'],
    }
    alternatives { 'pip':
      path    => '/usr/bin/pip2.7',
      require => Class['::st2::profile::python'],
    }

    alternative_entry {'/usr/bin/virtualenv-2.7':
      ensure   => present,
      altlink  => '/usr/bin/virtualenv',
      altname  => 'virtualenv',
      priority => 10,
      require  => Class['::st2::profile::python'],
    }
    alternatives { 'virtualenv':
      path    => '/usr/bin/virtualenv-2.7',
      require => Class['::st2::profile::python'],
    }

    Alternatives['virtualenv'] -> Exec<| tag == 'virtualenv' |>
  }

}
