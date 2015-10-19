class role::st2express {
  $_enable_hubot = hiera('hubot', true)

  include ::profile::infrastructure
  include ::profile::st2server
  include ::profile::auth_backend_pam
  include ::profile::users
  include ::st2migrations

  # This is not the proper place for this. Need to find a profile
  # for these classes to live in
  class { '::st2::helper::auth_manager':
    auth_mode     => 'standalone',
    auth_backend  => 'pam',
    debug         => false,
    syslog        => true,
  }

  if $_enable_hubot {
    include ::profile::hubot
  }
}
