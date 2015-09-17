class role::st2enterprise {
  $_enable_hubot = hiera('hubot', true)

  include ::profile::infrastructure
  include ::profile::st2server
  include ::profile::st2flow
  include ::profile::st2rbac
  include ::profile::enterprise_auth_backend
  include ::profile::users
  include ::st2migrations

  if $_enable_hubot {
    if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
      notify { 'Hubot is not supported on this platform': }
    } else {
      include ::profile::hubot
    }
  }
}
