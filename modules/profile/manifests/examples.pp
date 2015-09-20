class profile::examples {

  $examples_script = $osfamily ? {
    'Ubuntu' => '/usr/lib/python2.7/dist-packages/st2common/bin/st2-setup-examples',
    'RedHat' => '/usr/lib/python2.7/site-packages/st2common/bin/st2-setup-examples'
  }
  
  exec {'examples':
    path     => '/bin:/usr/bin"
    command  => "python2.7 ${examples_script}"
    creates  => '/opt/stackstorm/packs/examples'
  }
}
