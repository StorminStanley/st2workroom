class profile::hubot(
  $enable         = true,
  $bot_name       = 'hubot',
  $version        = undef,
  $docker_image   = 'stackstorm/hubot',
  $data_container = "st2-hubot-${bot_name}",
  $http_port      = '8081',
  ) {

  include ::profile::redis

  # Get ENV vars hash from Hiera, and map to an array for Docker
  $_adapter        = hiera('hubot::adapter', 'shell')
  $_alias          = hiera('hubot::chat_alias', '!')
  $_hiera_env_vars = hiera_hash('hubot::env_export', {})
  $_env_vars       = $_hiera_env_vars.map |$_key, $_value| {
    "${_key}=${_value}"
  }

  if ! defined(Class['docker']) {
    fail('[profile::hubot]: Docker is not enabled on this host.')
  }

  if $enable {
    ## Download main docker image for Hubot
    docker::image { $docker_image:
      ensure => present,
      tag    => $version,
      notify => Exec["create st2-hubot-${name} data container"],
    }

    exec { "create st2-hubot-${name} data container":
      command     => join([
        'docker',
        'create',
        '-v',
        '/app',
        '-name',
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

    docker::run { "st2-hubot-${name}":
      image            => $docker_image,
      command          => join([
        '/app/bin/hubot',
        '-a',
        $_adapter,
        '--name',
        $bot_name,
        '--alias',
        $_alias,
      ], ' '),
      volumes_from     => [
        $data_container,
      ],
      env              => $_env_vars,
      ports            => [
        "${http_port}:8080",
      ],
      extra_parameters => ['--restart=always'],
      require          => [
        Docker::Image[$docker_image],
        Exec["create st2-hubot-${name} data container"],
      ],
    }
  }

  # Some hubot adapters are flakey, and randomly die.
  # This is a workaround until upstream PRs are merged.
  cron { 'restart hubot':
    command => "service st2-hubot-${name} restart",
    user    => 'root',
    hour    => '*/12',
  }
}
