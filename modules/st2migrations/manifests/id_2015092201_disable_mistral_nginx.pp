# Migration: Disable StackStorm services for Upgrade
#
# It is a pretty good bet that the first time we run
# Puppet to converge, we'll be getting new code. If
# we happen to be running in an environment where
# services have been pre-packaged on the system, then
# we should ensure that they have stopped so that new code
# will be properly started by the system.
class st2migrations::id_2015092201_disable_mistral_nginx {
  $_rundir = $::st2migrations::exec_dir

  if $::st2migration_2015092201_disable_mistral_nginx != 'completed' {
    $_shell_script = "#!/usr/bin/env sh
      service nginx stop
      service mistral stop
    "

    file { "${_rundir}/stop_nginx_mistral_for_upgrade":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $_shell_script,
      notify  => Exec['stop nginx mistral for upgrade'],
    }
    exec { 'stop nginx mistral for upgrade':
      command => "${_rundir}/stop_st2services_for_upgrade",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      before  => [
        Facter::Fact['st2migration_2015092201_disable_mistral_nginx'],
        Class['::nginx'],
        Class['::st2::profile::mistral'],
      ],
    }
    facter::fact { 'st2migration_2015092201_disable_mistral_nginx':
      value => 'completed',
    }
  }
}
