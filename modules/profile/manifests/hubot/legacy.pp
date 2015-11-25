class profile::hubot::legacy (
  $bot_name = 'hubot',
  $version  = '0.1.1',
) {
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    notify { 'Hubot is not supported on this platform': }
  } else {
    ## Common
    class { '::hubot':
      install_nodejs => false,
    }
    class { '::nodejs':
      repo_url_suffix => 'node_0.12',
    }

    $_hubot_bin_dir = '/opt/hubot/hubot'
    $_hubot_user    = 'hubot'

    # These packages are used to pre-download a ton of chat
    # adapters and their dependencies for offline usage.
    $_npm_packages  = {
      'hubot-scripts' => latest,
      'hubot-stackstorm' => '^0.2.5',
      'hubot-irc' => latest,
      'hubot-flowdock' => latest,
      'hubot-slack' => latest,
      'hubot-xmpp' => latest,
      'hubot-hipchat' => latest,
    }

    if $::osfamily == 'RedHat' {
      package { 'libicu-devel':
        ensure => 'present'
      }

      # Needed for XMPP and HipChat adapters
      if $::operatingsystemmajversion == '6' {
        package { 'nodejs-node-expat':
          ensure => present,
        }
      }
    }

    Exec<| title == 'Hubot init' |> {
      path => '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin',
    }

    # Accomidate a custom hubot install vs default
    if $::hubot::git_source != undef {
      $hiera_env_vars = hiera_hash('hubot::env_export', {})
      $stackstorm_env_vars = {
        'EXPRESS_PORT' => '8081',
      }
      $env_vars = merge($hiera_env_vars, $stackstorm_env_vars)

      $hubot_home     = "${::hubot::root_dir}/${bot_name}"
      $adapter        = $::hubot::adapter
      $chat_alias     = $::hubot::chat_alias

      file { '/etc/init/hubot.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/hubot/upstart_init.erb'),
        before  => Service['hubot'],
      }

      ## Non-ideal hacks, but prevents the need for forking
      ## upstream module
      Service<| title == 'hubot' |> {
        provider => upstart,
      }
      File<| tag == 'hubot::config' |> ->
      Vcsrepo<| title == $_hubot_bin_dir |> {
        revision => undef,
      }
    }

    #  Some hubot adapters are flakey, and randomly die. This is a workaround until
    #  upstream PRs are merged.
    cron { 'restart hubot':
      command => 'service hubot restart',
      user    => 'root',
      hour    => '*/12',
    }

    # Pre-install all the necessary adapters for offline use
    Exec<| tag == 'nodejs::npm' |> {
      environment => 'HOME=/opt/hubot',
    }

    # Only attempt to install the adapters a single time. Hubot
    # will attempt to refresh on boot, so we do not need to look
    # on every convergence attempt.
    if $::hubot_adapters_version != $version {
      $_npm_packages.each |String $name, String $value| {
        nodejs::npm { $name:
          ensure => $value,
          target => $_hubot_bin_dir,
          user   => $_hubot_user,
          before => Facter::Fact['hubot_adapters_version'],
        }
      }
    }

    facter::fact { 'hubot_adapters_version':
      value => $version,
    }
  }
}
