# Definition: adapter::st2_uwsgi_init
#
#  This adapter creates an init script calling UWSGI for
#  a given StackStorm subsystem. This is to disable the
#  default standalone server started by st2ctl, but to
#  keep that script still usable.
#
define adapter::st2_uwsgi_init (
  $subsystem = $name,
) {
  if ! defined(Class['uwsgi']) and ! defined(Class['::st2::profile::server']) {
    fail("[Adapter::St2_uwsgi_init[${name}]: This adapter can only be used in conjunction with 'uwsgi' and 'st2::profile::server")
  }

  if $::osfamily != 'Debian' {
    fail("[Adapter::St2_uwsgi_init[${name}]: This adapter only supports Debian, currently")
  }

  $_subsystem_map = {
    'api'          => 'api',
    'st2api'       => 'api',
    'auth'         => 'auth',
    'st2auth'      => 'auth',
    'installer'    => 'installer',
    'st2installer' => 'installer',
  }
  $_subsystem = $_subsystem_map[$subsystem]
  $_subsystem_upcase = upcase($_subsystem)

  file_line { "st2 disable standalone ${subsystem}":
    path => '/etc/environment',
    line => "ST2_DISABLE_${_subsystem_upcase}=true",
  }

  file { "/etc/init/st2${_subsystem}-uwsgi.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('adapter/st2_uwsgi_init/init.conf.erb'),
    notify  => Service["st2${_subsystem}-uwsgi"],
  }

  service { "st2${_subsystem}-uwsgi":
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
