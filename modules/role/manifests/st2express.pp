class role::st2express {
  $_enable_hubot = hiera('hubot', true)

  include ::profile::infrastructure
  include ::profile::st2server
  include ::profile::users
  class { '::st2migrations': }

  if $_enable_hubot {
    if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
      notify { 'Hubot is not supported on this platform': }
    } else {
      include ::profile::hubot
    }
  }
}
