# Class: profile::st2rbac
#
# Enable RBAC for StackStorm
class profile::st2rbac {
  ini_setting { 'disable st2 rbac':
    ensure  => present,
    path    => '/etc/st2/st2.conf',
    section => 'rbac',
    setting => 'enable',
    value   => 'False',
    require => Class['::profile::st2server'],
  }
}
