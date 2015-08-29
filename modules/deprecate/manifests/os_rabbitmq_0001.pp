# Class: deprecate::os_rabbitmq_0001
#
# This class is designed to uninstall the OS RabbitMQ
# Because Puppet, this has to happen in stages over
# many runs. The first key is to ensure the service is
# stopped, followed by uninstalling the package itself.
#
# Uses facter facts to leave stage breadcrumbs
class deprecate::os_rabbitmq_0001(
  $enforce = true,
) {
  $_stage = $::deprecate_os_rabbitmq_0001_stage

  case $_stage {
    undef: {
      $_service_manage = true
      $_service_ensure = 'stopped'
      $_package_ensure = undef

      $_next_stage = 'remove'
    }
    'remove': {
      $_service_ensure = undef
      $_service_manage = false
      $_package_ensure = 'absent'

      $_next_stage = 'complete'
    }
    default: {
      $_service_ensure = undef
      $_service_manage = false
      $_package_ensure = 'absent'

      $_next_stage = undef
    }
  }

  if $enforce {
    class { '::rabbitmq':
      manage_repos   => false,
      admin_enable   => false,
      service_manage => $_service_manage,
      service_ensure => $_service_ensure,
      package_ensure => $_package_ensure,
    }

    if $_next_stage {
      file { '/etc/facter/facts.d/deprecate_os_rabbitmq_0001_stage.txt':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "deprecate_os_rabbitmq_0001_stage=${_next_stage}",
        require => Class['::rabbitmq'],
      }
    }
  }
}
