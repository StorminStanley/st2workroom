class profile::rabbitmq {
  $_version = hiera('rabbitmq::version', '3.5.4')
  include ::docker

  docker::image { 'rabbitmq':
    ensure => present,
    tag    => $_version,
  }

  docker::run { 'rabbitmq':
    image    => 'rabbitmq',
    hostname => 'rabbitmq',
    volumes  => [
      '/var/lib/rabbitmq:/var/lib/rabbitmq',
    ],
    ports    => [
      '5672:5672',
    ],
    require  => [
      Docker::Image['rabbitmq'],
      Class['::deprecate::os_rabbitmq_0001'],
    ],
  }
}
