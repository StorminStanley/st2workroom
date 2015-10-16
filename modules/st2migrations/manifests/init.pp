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

  if $::datacenter == 'us-east-1' {
    include ::st2migrations::id_2015091401_move_st2api_to_gunicorn
    include ::st2migrations::id_2015092102_disable_st2services_for_upgrade
    include ::st2migrations::id_2015092101_refresh_mistral_venv
    include ::st2migrations::id_2015092201_disable_mistral_nginx
  }
}
