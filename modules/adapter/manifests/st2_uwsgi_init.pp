# Definition: adapter::st2_uwsgi_init
#
#  This adapter creates an init script calling UWSGI for
#  a given StackStorm subsystem. This is to disable the
#  default standalone server started by st2ctl, but to
#  keep that script still usable.
#
define adapter::st2_uwsgi_init (
  $subsystem      = $name,
  $enable_restart = true,
) {
  include ::st2::params
  include ::profile::uwsgi

  $_init_type = $::st2::params::init_type

  if ! defined(Class['uwsgi']) and ! defined(Class['::st2::profile::server']) {
    fail("[Adapter::St2_uwsgi_init[${name}]: This adapter can only be used in conjunction with 'uwsgi' and 'st2::profile::server")
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

  case $_init_type {
    'upstart': {
        $_init_file = "/etc/init/${_subsystem}.conf"
        $_init_mode = '0644'
        $_template = $_subsystem ? {
          'mistral-api' => 'anchor.conf.erb',
          default       => 'init.conf.erb',
        }
      }
    'systemd': {
      $_init_file = "/etc/systemd/system/${_subsystem}.service"
      $_init_mode = '0644'
      $_template = $_subsystem ? {
        'mistral-api' => 'anchor.service.erb',
        default       => 'init.service.erb',
      }
    }
    'init': {
      $_init_file = "/etc/init.d/${_subsystem}"
      $_init_mode = '0755'
      $_template = $_subsystem ? {
        'mistral-api' => 'anchor.sysv.erb',
        default       => 'init.sysv.erb',
      }
    }
    default: {
      fail("[adapter::st2_uwsgi_init] Unable to setup adapter for Init System ${_init_type}. Not supported")
    }
  }

  file { $_init_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => $_init_mode,
    content => template("adapter/st2_uwsgi_init/${_template}"),
    notify  => Service[$_subsystem],
  }

  service { $_subsystem:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      Class['st2::profile::server'],
      Class['::profile::uwsgi'],
    ],
  }

  # Subscribe to Uwsgi Apps of the same name.
  File[$_init_file] ~> Service[$_subsystem]
  Ini_setting<| tag == 'st2::config' |> ~> Service[$_subsystem]

  if $enable_restart == false {
    Service[$_subsystem] {
      restart => 'exit 0',
    }
  }
}
