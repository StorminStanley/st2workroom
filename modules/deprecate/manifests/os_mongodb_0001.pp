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
  $_stage = $::deprecate_os_mongodb_0001_stage

  case $_stage {
    undef: {
      $_service_ensure = 'stopped'
      $_service_enable = 'false'
      $_package_ensure = undef

      # The next stage to process
      $_next_stage = 'stopped'
    }
    'stopped': {
      $_service_ensure = 'stopped'
      $_service_enable = 'false'
      $_package_ensure = 'absent'

      # The next stage to process
      $_next_stage = 'uninstalled'
    }
    default: {
      $_next_stage = undef
    }
  }

  if $enforce {
    class { '::mongodb::server':
      service_ensure => $_service_ensure,
      package_ensure => $_package_ensure,
    }

    # Set the breadcrumb for the next run.

    if $_next_stage {
      file { '/etc/facter/facts.d/deprecate_os_mongodb_0001_stage.txt':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "deprecate_os_mongodb_0001_stage=${_next_stage}",
        require => Class['::mongodb::server'],
      }
    }
  }
}
