class profile::hubot::docker (
  $enable         = true,
  $bot_name       = 'hubot',
  $version        = undef,
  $docker_image   = 'stackstorm/hubot',
  $data_container = 'hubotdata',
  $http_port      = '8081',
  ) {

  # Get ENV vars hash from Hiera, and map to an array for Docker
  $_adapter         = hiera('hubot::adapter', 'shell')
  $_alias           = hiera('hubot::chat_alias', '!')
  $_hiera_env_vars  = hiera_hash('hubot::env_export', {})
  $_user_env_vars   = {
    "HUBOT_NAME"    => $bot_name,
    "HUBOT_ADAPTER" => $_adapter,
    "HUBOT_ALIAS"   => $_alias,
  }
  $_all_env_vars    = merge($_hiera_env_vars, $_user_env_vars)
  $_docker_env_vars = $_all_env_vars.map |$_key, $_value| {
    "${_key}=${_value}"
  }
  $_run_image = $version ? {
    undef   => $docker_image,
    default => "${docker_image}:${version}",
  }

  if ! defined(Class['docker']) {
    fail('[profile::hubot]: Docker is not enabled on this host.')
  }

  if $enable {
    ## Download main docker image for Hubot
    docker::image { $docker_image:
      ensure    => present,
      image_tag => $version,
    }

    docker::run { 'hubot':
      image            => $_run_image,
      env              => $_docker_env_vars,
      ports            => [
        "${http_port}:8080",
      ],
      extra_parameters => ['--restart=always'],
      require          => [
        Docker::Image[$docker_image],
      ],
    }
  }
}
