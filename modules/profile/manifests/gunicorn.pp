class profile::gunicorn {
  # Ensure gunicorn is installed correctly
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    ensure_resource('exec', 'pip2.7 install gunicorn', {
      'path'    => '/usr/sbin:/usr/bin:/sbin:/bin',
      'creates' => '/usr/bin/gunicorn',
    })
  } else {
    ensure_resource('python::pip', 'gunicorn', {
      'ensure' => 'present',
    })
  }
}
