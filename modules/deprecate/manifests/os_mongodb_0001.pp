# Class: deprecate::os_mongodb_0001
#
# This class is designed to uninstall the OS RabbitMQ
# Because Puppet, this has to happen in stages over
# many runs. The first key is to ensure the service is
# stopped, followed by uninstalling the package itself.
#
# Uses facter facts to leave stage breadcrumbs
class deprecate::os_mongodb_0001(
  $enforce = true,
) {
  $_enforced = $::deprecate_os_mongodb_0001_status

  if ! $_enforced {
    class { '::mongodb::server':
      service_ensure => 'stopped',
      service_enable => 'false',
    }
    file { '/etc/facter/facts.d/deprecate_os_mongodb_0001_stage.txt':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => 'deprecate_os_mongodb_0001_stage=true',
      require => Class['::mongodb::server'],
    }
  }
}
