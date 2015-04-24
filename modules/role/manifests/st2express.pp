class role::st2express {
  include ::profile::st2server
  include ::profile::users

  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    notify { 'Hubot is not supported on this platform': }
  } else {
    include ::profile::hubot
  }
}
