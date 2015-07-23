class profile::ec2 {
  if $::osfamily == 'Debian' {
    sudo::conf { 'ubuntu':
      ensure  => present,
      content => 'ubuntu ALL=(ALL) NOPASSWD: ALL',
    }
  }
}
