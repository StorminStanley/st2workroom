define users(
  $ensure      = present,
  $username    = $name,
  $password    = undef,
  $home        = "/home/${name}",
  $sshkey      = undef,
  $sshkeytype  = 'ssh-rsa',
  $shell       = '/bin/bash',
  $admin       = false,
  $managehome  = true,
  $uid         = undef,
  $gid         = undef,
) {

  if $ensure == present {
    $_password = $password ? {
      true    => generate('/bin/sh', '-c', "mkpasswd -m sha-512 ${password} | tr -d '\n'"),
      default => undef,
    }
    user{ $username:
      ensure      => $ensure,
      uid         => $uid,
      gid         => $gid,
      shell       => $shell,
      managehome  => $managehome,
      require => Group[$username]
    }

    if $password {
      exec { "Setting ${username} password":
        command   => "echo '${username}:${password}' | chpasswd ${username}",
        path      => '/bin:/usr/sbin',
        subscribe => User[$username],
      }
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
    sudo::conf { "${username}-admin":
      ensure   => $ensure,
      priority => 10,
      content  => "${username}    ALL=(ALL)       NOPASSWD: ALL",
    }
  }
}
