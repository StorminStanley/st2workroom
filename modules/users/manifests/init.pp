define users(
  $ensure      = present,
  $username    = $name,
  $home        = "/home/${name}",
  $sshkey      = undef,
  $sshkeytype  = 'ssh-rsa',
  $shell       = '/bin/bash',
  $admin       = false,
  $uid,
  $gid,
) {

  if $ensure == present {
    user{ $username:
      ensure      => $ensure,
      uid         => $uid,
      gid         => $gid,
      shell       => $shell,
      managehome  => true,
      require => Group[$username]
    }

    group{ $username:
      ensure => $ensure,
      gid    => $gid
    }

    file{ $home:
      ensure      => 'directory',
      owner       => $username,
      group       => $username,
      mode        => '0700',
      require     => User[$username]
    }

    file{ "${home}/.ssh":
      ensure  => 'directory',
      owner   => $username,
      group   => $username,
      mode    => '0700',
      require => File["${home}"]
    }

    if $sshkey and $sshkeytype {
      ssh_authorized_key{"${username}-${sshkeytype}-ssh_authorized_key":
        ensure      => $ensure,
        user        => $username,
        type        => $sshkeytype,
        key         => $sshkey,
        require   => File["${home}/.ssh"]
      }
    }
  } else {
    user{ $username:
      ensure  => absent,
      require => Service["user@${username}.service"]
    }
  }

  if $admin {
    include ::sudo
    sudo::conf { "${username}-admin":
      ensure   => $ensure,
      priority => 10,
      content  => "${username}    ALL=(ALL)       NOPASSWD: ALL",
    }
  }
}
