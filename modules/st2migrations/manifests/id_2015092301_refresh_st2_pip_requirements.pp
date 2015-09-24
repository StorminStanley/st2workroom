# Migration: Refresh StackStorm PIP requirements
#
# It is a pretty good bet that the first time we run
# Puppet to converge, we'll be getting new code. If
# we happen to be running in an environment where
# services have been pre-packaged on the system, then
# we need to ensure that requirements are updated
# until we have well-crafted packages
class st2migrations::id_2015092301_refresh_st2_pip_requirements {
  $_rundir = $::st2migrations::exec_dir

  if $::st2migration_2015092301_refresh_st2_pip_requirements != 'completed' {
    $_shell_script = "#!/usr/bin/env sh
    if [ -f /etc/facter/facts.d/st2server_bootstrapped.txt ]; then
      rm -rf /etc/facter/facts.d/st2server_bootstrapped.txt
    fi
    "

    file { "${_rundir}/remove_st2server_bootstrapped_flag":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $_shell_script,
      notify  => Exec['remove st2server bootstrapped flag'],
    }
    exec { 'remove st2server bootstrapped flag':
      command => "${_rundir}/remove_st2server_bootstrapped_flag",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      before  => [
        Facter::Fact['st2migration_2015092301_refresh_st2_pip_requirements'],
        Class['::st2::profile::server'],
      ],
    }
    facter::fact { 'st2migration_2015092301_refresh_st2_pip_requirements':
      value => 'completed',
    }
  }
}
