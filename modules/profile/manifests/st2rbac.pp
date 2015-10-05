# Class: profile::st2rbac
#
# Enable RBAC for StackStorm
class profile::st2rbac {
  $_enterprise_token = hiera('st2enterprise::token', undef)

  if $_enterprise_token {
    ini_setting { 'disable st2 rbac':
      ensure  => present,
      path    => '/etc/st2/st2.conf',
      section => 'rbac',
      setting => 'enable',
      value   => 'False',
      require => Class['::profile::st2server'],
    }

    # Create default admin role assignment for root_cli user
    st2::rbac { $_root_cli_username:
      description  => 'Default admin role assignments created by the installer',
      roles        => [
          'admin'
      ]
    }

    # Create default system_admin role assignment for admin user created during installation
    # Note: Assignment is only created once the installer has completed.
    $_users = hiera_hash('users', {}).keys()
    if size($_users) >= 1 {
        $_admin_user = $_users[0]

        st2::rbac { $_admin_user:
          description  => 'Default system_admin role assignments created by the installer',
          roles        => [
              'system_admin'
          ]
        }
    }
  }
}
