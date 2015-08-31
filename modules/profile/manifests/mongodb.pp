class profile::mongodb {
  include ::docker
  $_version = hiera('mongodb::version', '2.4.14')

  if $::osfamily == 'Debian' {
    # Needed to build mongoengine
    package { 'mongodb-dev':
      ensure => present
    }
  }

  docker::image { 'mongo':
    ensure    => present,
    image_tag => $_version,
  }

  docker::run { 'mongo':
    image   => 'mongo',
    volumes => [
      '/var/lib/mongodb:/data/db',
    ],
    ports   => [
      '27017:27017',
    ],
    require => [
      Docker::Image['mongo'],
    ],
  }
}
