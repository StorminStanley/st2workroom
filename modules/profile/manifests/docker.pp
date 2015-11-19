class profile::docker {
  include ::st2::params
  $_init_type = $::st2::params::init_type
  $_compose_version = hiera('docker-compose::version', '1.4.0')
  $_http_proxy = hiera('system::http_proxy', undef)

  class { '::docker':
    proxy => $_http_proxy,
  }

  $_url = 'https://github.com/docker/compose/releases/download/1.4.0/docker-compose-`uname -s`-`uname -m`'
  $_output_file = '/usr/bin/docker-compose'

  exec { 'install docker-compose':
    command => "curl -L ${_url} > ${_output_file}",
    creates => $_output_file,
    path    => '/usr/bin:/bin:/usr/sbin:/sbin',
    before  => File[$_output_file],
  }
  file { $_output_file:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # This block disables timeouts for docker on systemd. Specifically,
  # an issue arises while waiting for the base storage image to be
  # provisioned when slow disk is involved.
  #
  # Ref: https://github.com/docker/docker/issues/16653
  #
  # This adds a local override to the systemd definion, allowing
  # safe and sound execution.
  #
  # See http://www.freedesktop.org/software/systemd/man/systemd.unit.html
  # for additional details on implementation
  if $_init_type == 'systemd' {
    $_docker_override_dir = '/etc/systemd/system/docker.service.d'
    $_docker_override = @("EOF")
    [Service]
    TimeoutStartSec=0
    | EOF

    file { $_docker_override_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    file { "${_docker_override_dir}/local.conf":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => $_docker_override,
    }

    Package['docker']
    -> File["${_docker_override_dir}/local.conf"]
    ~> Exec['systemctl-daemon-reload']
    -> Service['docker']
  }
}
