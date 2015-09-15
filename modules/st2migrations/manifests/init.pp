class st2migrations (
  $exec_dir = "${::settings::vardir}/st2migrations",
) {
  file { $exec_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0770',
  }

  # Register all migrations to activate here
  include ::st2migrations::id_2015091401_move_pecan_server_to_uwsgi
}
