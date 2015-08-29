class puppet::masterless(
  $cron        = true,
  $run_at_boot = false,
) inherits puppet {
  $offset = fqdn_rand(30)

  $_load_role = "::role::${::role}"
  if $::role and defined($_load_role) {
    include $_load_role
  }

  if $cron {
    cron { 'puppet-apply':
      ensure  => present,
      user    => 'root',
      minute  => $offset,
      command => "${::settings::confdir}/script/puppet-apply",
    }
  }

  if $run_at_boot {
    cron { 'puppet-apply':
      ensure  => present,
      user    => 'root',
      special => 'reboot',
      command => "${::settings::confdir}/script/puppet-apply",
    }
  }

  file { ['/usr/bin/puprun', '/usr/bin/update-system']:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => "${::settings::confdir}/script/puppet-apply",
  }

  file { "${::settings::confdir}/current_environment":
    ensure  => file,
    content => "${::environment}\n",
  }

  file { ['/etc/facter', '/etc/facter/facts.d']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "/etc/facter/facts.d/role.txt":
    ensure  => file,
    content => "role=${::role}\n",
  }
}
