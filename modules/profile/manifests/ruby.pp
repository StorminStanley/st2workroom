class profile::ruby {
  class { '::ruby':
    gems_version => 'latest',
  }

  include '::ruby::dev'
}
