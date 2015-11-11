class profile::docker {
  $_compose_version = hiera('docker-compose::version', '1.4.0')

  class { '::docker':
    extra_parameters => ['--storage-opt dm.basesize=20G'],
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
}
