class role::st2express {
  $_enable_hubot = hiera('hubot', true)

  include ::profile::infrastructure
  include ::profile::st2server
  include ::profile::users
  include ::st2migrations

  if $_enable_hubot {
    include ::profile::hubot
  }
}
