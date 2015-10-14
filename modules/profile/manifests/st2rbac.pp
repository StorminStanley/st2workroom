# Class: profile::st2rbac
#
# Enable RBAC for StackStorm and write default role assignments.
class profile::st2rbac {
  $_enterprise_token = hiera('st2enterprise::token', undef)
  if $_enterprise_token {
    # Enable RBAC if enterprise token is present, write default role assignments
    ini_setting { 'enable st2 rbac':
      ensure  => present,
      path    => '/etc/st2/st2.conf',
      section => 'rbac',
      setting => 'enable',
      value   => 'True',
      require => Class['::profile::st2server'],
    }

    # Create default admin role assignment for root_cli user
    $_root_cli_username = $::profile::st2server::_root_cli_username
    st2::rbac { $_root_cli_username:
      description  => 'Default admin role assignments created by the installer',
      roles        => [
          'admin'
      ]
    }

    # Create default admin role assignment for ChatOps user
    $_hubot_data = hiera_hash('hubot::env_export', {})
    if size($_hubot_data.keys()) >= 1 {
        $_chatops_bot_username = $_hubot_data['ST2_AUTH_USERNAME']
        st2::rbac { $_chatops_bot_username:
          description  => 'Default admin role assignment created by the installer',
          roles        => [
              'admin'
          ]
        }
    }

    # Create default system_admin role assignment for admin user created during installation
    # Note: Assignment is only created once the installer has completed.
    $_users = hiera_hash('users', {}).keys()
    if size($_users) >= 1 {
        $_admin_user = $_users[0]

        st2::rbac { $_admin_user:
          description  => 'Default system_admin role assignment created by the installer',
          roles        => [
              'system_admin'
          ]
        }
      }
    }
  }
}
