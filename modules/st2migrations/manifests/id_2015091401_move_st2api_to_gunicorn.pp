# Migration: Move pecan server to uWSGI
#
# Previous iterations of `st2workroom` were built
# with st2api being controlled via st2ctl. This
# migration ensures that the existing process is gone
# so the state applied in Stage['main'] can continue,
# specifically nginx which now takes over 0.0.0.0
# where before it only listened on eth0
class st2migrations::id_2015091401_move_st2api_to_gunicorn {
  $_rundir = $::st2migrations::exec_dir

  if ! $::st2migration_2015091401_move_st2api_to_uwsgi {
    $_shell_script = "#!/usr/bin/env sh
    service st2api stop
    ps ax | grep st2api | grep python | awk '{print \$1}' | xargs kill -9
    ps ax | grep st2api | grep uwsgi | awk '{print \$1}' | xargs kill -9"

    file { "${_rundir}/kill_st2api_standalone":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $_shell_script,
      notify  => Exec['terminate st2api application'],
    }
    exec { 'terminate st2api application':
      command => "${_rundir}/kill_st2api_standalone",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      before  => [
        Facter::Fact['st2migration_2015091401_move_st2api_to_uwsgi'],
        Service['nginx'],
      ],
    }
    facter::fact { 'st2migration_2015091401_move_st2api_to_uwsgi':
      value => 'completed',
    }

    File<| tag == 'adapter::st2_gunicorn_init' |>
    -> Exec['terminate st2api application']
  }
}
