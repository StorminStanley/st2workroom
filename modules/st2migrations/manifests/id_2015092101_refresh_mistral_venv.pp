# Migration: Refresh Mistral vEnv
#
# While moving to newer version of Mistral venv, we need to
# clear out the old 0.13.x venv and allow the new venv to
# to be built out with updated pip dependencies.
class st2migrations::id_2015092101_refresh_mistral_venv {
  $_rundir = $::st2migrations::exec_dir
  $_mistral_root = $::st2::profile::mistral::_mistral_root

  if $::st2migration_2015092101_refresh_mistral_venv != 'completed-v2' {
    $_shell_script = "#!/usr/bin/env sh
    service mistral stop

    # https://github.com/StackStorm/puppet-st2/blob/master/manifests/profile/mistral.pp#L154
    if [ -d /opt/openstack/mistral/.venv ]; then
      rm -rf /opt/openstack/mistral/.venv
    fi

    # https://github.com/StackStorm/puppet-st2/blob/master/manifests/profile/mistral.pp#L124
    if [ -d /etc/mistral/actions/st2mistral ]; then
      rm -rf /etc/mistral/actions/st2mistral
    fi

    # https://github.com/StackStorm/puppet-st2/blob/master/manifests/profile/mistral.pp#L275
    if [ -f /etc/mistral/database_setup.lock ]; then
      rm -rf /etc/mistral/database_setup.lock
    fi

    su postgres -c 'psql -c \"DROP DATABASE IF EXISTS mistral;\"'
    su postgres -c 'psql -c \"DROP USER IF EXISTS mistral;\"'
    "

    file { "${_rundir}/refresh_mistral_venv":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $_shell_script,
      notify  => [
        Exec['run mistral venv migration'],
        Vcsrepo['/etc/mistral/actions/st2mistral'],
      ],
    }
    exec { 'run mistral venv migration':
      command => "${_rundir}/refresh_mistral_venv",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      require => Class['::postgresql'],
      before  => [
        Facter::Fact['st2migration_2015092101_refresh_mistral_venv'],
        Class['::st2::profile::mistral'],
      ],
    }

    ## Install db driver manually
    python::pip { 'psycopg2':
      ensure     => present,
      virtualenv => "${_mistral_root}/.venv",
      require    => Python::Virtualenv[$_mistral_root],
      before     => Service['mistral'],
    }
    facter::fact { 'st2migration_2015092101_refresh_mistral_venv':
      value => 'completed-v2',
    }
  }
}
