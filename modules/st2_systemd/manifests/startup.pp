# Definition: st2_systemd
#
#  Lets create some Systemd scripts
#
define st2_systemd::startup (
  $st2_process  = undef,
  $process_type = single
  ) {

  if $process_type = multi {
    $type = "${process_type}@"
  } else {
    $type = ''
  }
  
  file{"/etc/systemd/system/${st2_process}${type}.service":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    content => template("modules/st2_systemd/st2service_${process_type}.service.erb"),
    notify  => Service["${st2_process}"],
  }

}