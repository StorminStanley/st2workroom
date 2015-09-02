class profile::python {
  include ::st2::profile::python

  exec { 'update-pip':
    command     => 'pip install -U pip',
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    refreshonly => true,
  }

  Exec['update-pip'] -> Python::Pip<||>

}
