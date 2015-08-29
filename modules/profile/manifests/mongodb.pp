class profile::mongodb {
  include ::deprecate::os_mongodb_0001

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
      Class['::deprecate::os_mongodb_0001'],
    ],
  }
}
