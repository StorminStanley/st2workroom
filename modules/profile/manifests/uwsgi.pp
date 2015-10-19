class profile::uwsgi {

  # Get upstream provider from StackStorm module
  include st2::params
  $_init_type = $::st2::params::init_type

  # Manage uwsgi with module, but install it using python pack
  # There is an odd error with installing directly via
  # the `pip` provider when used via Class['uwsgi']
  #
  # This class also disables the emperor service. To that end
  # to manage a service for StackStorm, you must use the
  # adapter::st2_uwsgi_service to start uwsgi services that
  # will be proxied to nginx.

  class { '::uwsgi':
    install_package     => false,
    log_rotate          => 'yes',
    service_ensure      => false,
    service_enable      => false,
    service_provider    => $_init_type,
    install_python_dev  => false,
    install_pip         => false,
    manage_service_file => false,
  }

  # Ensure uwsgi is installed correctly
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    ensure_resource('exec', 'pip2.7 install uwsgi', {
      'path'    => '/usr/sbin:/usr/bin:/sbin:/bin',
      'creates' => '/usr/bin/uwsgi',
      'before'  => Class['::uwsgi'],
    })
  } else {
    ensure_resource('python::pip', 'uwsgi', {
      'ensure' => 'present',
      'before' => Class['::uwsgi'],
    })
  }

  ## Upstream module only managed upstart/systemd, but there is no
  ## reason it shouldn't also be able to be used with older SysV
  ## systems.
  case $_init_type {
    'init': {
      file { '/etc/init.d/uwsgi':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => "#!/bin/sh\ntrue",
        before  => Class['::uwsgi'],
      }
    }
    'upstart': {
      file { '/etc/init/uwsgi.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "script\n  exec /bin/true\nend script",
        before  => Class['::uwsgi'],
      }
    }
    'systemd': {
      $_systemd_content = "[Unit]\nDescription=Dummy uWSGI\n[Service]\nType=oneshot\nExecStart=/bin/true\n[Install]\nWantedBy=multi-user.target"
      file { '/etc/systemd/system/uwsgi.service':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $_systemd_content,
        before  => Class['::uwsgi'],
      }
    }
  }
}
