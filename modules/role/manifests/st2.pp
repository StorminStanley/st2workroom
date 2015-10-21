class role::st2 {
  $_enable_hubot = hiera('hubot', true)
  $_enterprise_token = hiera('st2enterprise::token', false)
  $_enable_ldap = hiera('st2::ldap', false)

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

  # Enable Enterprise Features
  if $_enterprise_token {
    include ::profile::st2flow
    include ::profile::st2rbac
  }

  # Authentication Configuration
  if $_enable_ldap and $_enterprise_token {
    include ::profile::enterprise_auth_backend_ldap
  } elsif $_enable_ldap and ! $_enterprise_token {
    fail('[role::st2] Unable to enable LDAP without Enterprise Token. Please drop us a line at support@stackstorm.com if you are seeing this error incorrectly.')
  } else {
    include ::profile::auth_backend_pam
  }
}
