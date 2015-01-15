class puppet::deps {

}

class puppet::deps::agent {

  package{'puppet':
    ensure => 'installed'
  }
}

class puppet::deps::master {
  package{ 'puppet-server':
    ensure => 'latest'
  }
}
