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
      $_current_stage = 'stopped'
      $_service_ensure = 'stopped'
      $_package_ensure = 'absent'
      $_converged = false
    }
    'stopped': {
      $_current_stage = 'removed'
      $_service_ensure = 'stopped'
      $_package_ensure = 'absent'
      $_converged = true
    }
    default: {
      $_converged = true
    }
  }

  if $enforce {
    class { '::rabbitmq':
      manage_repos   => false,
      admin_enable   => false,
      service_ensure => $_service_ensure,
      package_ensure => $_package_ensure,
    }

# Set the breadcrumb for the next run.
    file { '/etc/facter/facts.d/deprecate_os_rabbitmq_0001_stage.txt':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => "deprecate_os_rabbitmq_0001_stage=${_current_stage}",
      require => Class['::rabbitmq'],
    }

    if ! $_converged {
      notify { "[deprecate::os_rabbitmq_0001]: WARNING: This module has not converged fully, currently on stage ${_current_stage} Please re-run puppet": }
    }
  }
}
