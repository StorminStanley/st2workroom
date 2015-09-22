# Migration: Disable StackStorm services for Upgrade
#
# It is a pretty good bet that the first time we run
# Puppet to converge, we'll be getting new code. If
# we happen to be running in an environment where
# services have been pre-packaged on the system, then
# we should ensure that they have stopped so that new code
# will be properly started by the system.
class st2migrations::id_2015092102_disable_st2services_for_upgrade {
  $_rundir = $::st2migrations::exec_dir

  if $::st2migration_2015092102_disable_st2services_for_upgrade != 'completed_2x' {
    $_shell_script = "#!/usr/bin/env sh
      service st2actionrunner stop
      service st2api stop
      service st2auth stop
      service st2resultstracker stop
      service st2sensorcontainer stop
      service st2notifier stop
      service st2rulesengine stop
      service st2installer stop
    "

    file { "${_rundir}/stop_st2services_for_upgrade":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $_shell_script,
      notify  => Exec['stop st2services for upgrade'],
    }
    exec { 'stop st2services for upgrade':
      command => "${_rundir}/stop_st2services_for_upgrade",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      before  => [
        Facter::Fact['st2migration_2015092102_disable_st2services_for_upgrade'],
        Class['::st2::profile::server'],
        Class['::profile::st2server'],
      ],
    }
    facter::fact { 'st2migration_2015092102_disable_st2services_for_upgrade':
      value => 'completed_2x',
    }
  }
}
