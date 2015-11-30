class profile::redis(
  $enable         = true,
  $version        = '3.0.5',
  $docker_image   = 'redis',
  $data_container = 'redisdata',
  $listen_port    = '6379',
  ) {

  if ! defined(Class['docker']) {
    fail('[profile::redis]: Docker is not enabled on this host.')
  }

  $_run_image = $version ? {
    undef   => $docker_image,
    default => "${docker_image}:${version}",
  }

  if $enable {
    ## Download main docker image for Redis
    docker::image { $docker_image:
      ensure    => present,
      image_tag => $version,
      notify    => Exec['create redis data container'],
    }

    exec { 'create redis data container':
      command     => join([
        'docker',
        'create',
        '-v',
        '/data',
        '--name',
        $data_container,
        $docker_image,
        '/bin/true',
      ], ' '),
      path        => [
        '/bin',
        '/sbin',
        '/usr/bin',
        '/usr/sbin',
      ],
      refreshonly => true,
    }

    docker::run { 'redis':
      image            => $_run_image,
      volumes_from     => [
        $data_container,
      ],
      ports            => [
        "${listen_port}:6379",
      ],
      extra_parameters => ['--restart=always'],
      require          => [
        Docker::Image[$docker_image],
        Exec['create redis data container'],
      ],
    }
  }
}
