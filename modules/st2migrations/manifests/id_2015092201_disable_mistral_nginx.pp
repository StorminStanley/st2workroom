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

  if $::st2migration_2015092201_disable_mistral_nginx != 'completed-2x' {
    $_shell_script = "#!/usr/bin/env sh
      rm -rf /etc/nginx/sites-enabled/mistral-api.conf
      service nginx stop
    "

    file { "${_rundir}/remove_mistral_nginx_config":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $_shell_script,
      notify  => Exec['remove mistral nginx config'],
    }
    exec { 'remove mistral nginx config':
      command => "${_rundir}/remove_mistral_nginx_config",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      before  => [
        Facter::Fact['st2migration_2015092201_disable_mistral_nginx'],
        Class['::st2::profile::mistral'],
      ],
      notify => Service['nginx'],
    }
    facter::fact { 'st2migration_2015092201_disable_mistral_nginx':
      value => 'completed-2x',
    }
  }
}
