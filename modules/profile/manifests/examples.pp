class profile::examples {

  $examples_script = $osfamily ? {
    'Debian' => '/usr/lib/python2.7/dist-packages/st2common/bin/st2-setup-examples',
    'Ubuntu' => '/usr/lib/python2.7/dist-packages/st2common/bin/st2-setup-examples',
    'RedHat' => '/usr/lib/python2.7/site-packages/st2common/bin/st2-setup-examples'
  }
  
  exec {'examples':
    path     => '/bin:/usr/bin',
    command  => "bash ${examples_script}",
    creates  => '/opt/stackstorm/packs/examples',
    requires => Service['st2api']
  }
}
