# Boilerplate template for st2migrations
define st2migrations::definition(
  $id,
  $version,
  $script,
) {
  $_rundir = $::st2migrations::exec_dir
  $_fact = "st2migration_${id}_${name}"

  $_default_notify = Exec["${_rundir}/${name}"]

  if $::facts[$_fact] != $version {
    file { "${_rundir}/${name}":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $script,
      notify  => [
        $_default_notify,
      ],
    }
    exec { "${_rundir}/${name}":
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      before  => [
        Facter::Fact[$_fact],
      ],
    }

    facter::fact { $_fact:
      value => $version,
    }
  }
}
