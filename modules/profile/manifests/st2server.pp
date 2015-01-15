class profile::st2server {
  class { '::st2':
    version  => hiera('st2::version', '0.6.0'),
  }
  include '::st2::stanley'

  class { '::st2::profile::mongodb': }
  -> class { '::st2::profile::rabbitmq': }
  -> class { '::st2::profile::nodejs': }
  -> class { '::st2::role::client': }
  -> class { '::st2::role::mistral':
    manage_mysql => true,
  }
  -> class { '::st2::role::server': }
}
