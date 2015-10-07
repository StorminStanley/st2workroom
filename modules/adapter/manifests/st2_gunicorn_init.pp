# Definition: adapter::st2_gunicorn_init
#
#  This adapter creates an init script calling UWSGI for
#  a given StackStorm subsystem. This is to disable the
#  default standalone server started by st2ctl, but to
#  keep that script still usable.
#
define adapter::st2_gunicorn_init (
  $subsystem = $name,
  $workers   = 1,
  $threads   = 1,
  $socket,
  $user,
  $group,
  ) {
  include puppet::params
  $_init_type = $puppet::params::init_type
  $_python_pack = $::st2::profile::server::_python_pack

  if $::osfamily != 'Debian' {
    fail("[Adapter::St2_gunicorn_init[${name}]: This adapter only supports Debian, currently")
  }

  $_subsystem_map = {
    'api'          => 'st2api',
    'st2api'       => 'st2api',
    'auth'         => 'st2auth',
    'st2auth'      => 'st2auth',
    'installer'    => 'st2installer',
    'st2installer' => 'st2installer',
    'mistral'      => 'mistral-api',
  }
  $_subsystem = $_subsystem_map[$subsystem]

  if $_init_type == 'upstart' {
    $_init_file = "/etc/init/${_subsystem}.conf"
    $_template = $_subsystem ? {
      'mistral-api' => 'anchor.conf.erb',
      default       => 'init.conf.erb',
    }
  } elsif $_init_type == 'systemd' {
    $_init_file = "/etc/systemd/system/${_subsystem}.service"
    $_template = $_subsystem ? {
      'mistral-api' => 'anchor.service.erb',
      default       => 'init.service.erb',
    }
  } else {
    fail("[adapter::st2_uwsgi_init] Unable to setup adapter for Init System ${_init_type}. Not supported")
  }

  file { $_init_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("adapter/st2_gunicorn_init/${_template}"),
    notify  => Service[$_subsystem],
  }

  service { $_subsystem:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      Python::Pip['gunicorn'],
      Class['st2::profile::server'],
    ],
  }
}
