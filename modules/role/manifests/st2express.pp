class role::st2express {
  $_enable_hubot = hiera('hubot', true)

  include ::profile::infrastructure
  include ::profile::st2server
  include ::profile::auth_backend_pam
  include ::profile::users
  include ::st2migrations

  st2::helper::auth_manager {
    auth_mode     => 'standalone',
    auth_backend  => 'pam',
    debug         => false,
    test_user     => false
  }

  if $_enable_hubot {
    include ::profile::hubot
  }
}
