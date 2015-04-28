class profile::hubot(
  $bot_name = 'hubot',
) {
  ## Common
  include ::hubot

  if $::osfamily == 'Debian' {
    package { 'npm':
      ensure => present,
    }
  }

  file { '/usr/bin/node':
    ensure => symlink,
    target => '/usr/bin/nodejs',
    require => Class['nodejs'],
  }

  Exec<| title == 'Hubot init' |> {
    path => '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin',
  }

  # Accomidate a custom hubot install vs default
  if $::hubot::git_source {
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
    Vcsrepo<| title == '/opt/hubot/hubot' |> {
      revision => undef,
    }
  }
}
