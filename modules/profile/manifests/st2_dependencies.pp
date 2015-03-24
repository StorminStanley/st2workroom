class profile::st2_dependencies {
  include ::st2::stanley
  include ::st2::profile::mongodb
  include ::st2::profile::python
  include ::st2::profile::rabbitmq
  class { '::st2::profile::mistral':
    manage_mysql => true,
  }
  class { 'screen': }
}
