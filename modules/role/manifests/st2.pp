class role::st2 {
  $_enable_hubot = hiera('hubot', true)
  $_enterprise_token = hiera('st2enterprise::token', undef)

  include ::profile::infrastructure
  include ::profile::st2enterprise
  include ::profile::st2server
  include ::profile::users
  include ::profile::examples
  include ::st2migrations
  include ::profile::bootstrap

  # Try to ensure bootstrap profile runs after StackStorm is confirmed working
  Class['::profile::st2server'] -> Class['::profile::bootstrap']

  if $_enable_hubot {
    if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
      notify { 'Hubot is not supported on this platform': }
    } else {
      include ::profile::hubot
    }
  }

  if $_enterprise_token {
    include ::profile::st2flow
    include ::profile::st2rbac
    include ::profile::enterprise_auth_backend_ldap
  } else {
    include ::profile::auth_backend_pam
  }
}
