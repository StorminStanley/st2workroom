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
    volumes_from => [
      'mongodata',
    ],
    ports   => [
      '27017:27017',
    ],
    require => [
      Docker::Image['mongo'],
      Docker::Run['mongodata'],
      File['/var/lib/mongodb'],
    ],
  }

  # Create Docker Data Container
  ## see http://docs.docker.com/userguide/dockervolumes/
  ## This is used to manage UID descrepencies between host
  ## and guest. In this way, data containers can be saved
  ## or pushed to docker registries for safe-keeping.
  docker::run { 'mongodata':
    image            => 'mongo',
    command          => '/bin/true',
    extra_parameters => '-v /data',
  }
}
