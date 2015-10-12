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

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    alternatives { 'virtualenv':
      path    => '/usr/bin/virtualenv-2.7',
      require => Class['::st2::profile::python'],
    }
    alternatives { 'pip':
      path    => '/usr/bin/pip-2.7',
      require => Class['::st2::profile::python'],
    }

    Alternatives['virtualenv'] -> Exec<| tag == 'virtualenv' |>
  }
}
