class puppet::masterless(
  $cron        = false,
  $run_at_boot = false,
) inherits puppet {
  $offset = fqdn_rand(30)

  $_load_role = "::role::${::role}"
  if $::role and defined($_load_role) {
    include $_load_role
  }

  class { '::facter':
    manage_package => false,
    path_to_facter => "${::settings::confdir}/bin/facter",
  }

  file { '/etc/facter/facts.d/facts.txt':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  facter::fact { 'puppet_role':
    value => $::role,
  }
  facter::fact { 'puppet_environment':
    value => $::environment,
  }

  File<| tag == 'puppet::masterless' |> -> Facter::Fact<||>

  if $cron {
    cron { 'puppet-periodic':
      ensure  => present,
      user    => 'root',
      minute  => $offset,
      command => "${::settings::confdir}/script/puppet-apply",
    }
  }

  if $run_at_boot {
    cron { 'puppet-boot':
      ensure  => present,
      user    => 'root',
      special => 'reboot',
      command => "${::settings::confdir}/script/puppet-apply",
    }
  }

  file { ['/usr/bin/puprun', '/usr/bin/update-system']:
    ensure => link,
    target => "${::settings::confdir}/script/puppet-apply",
  }

  # Ensure puppet logs are kept logrotating properly
  logrotate::rule { 'puppet-masterless':
    path => '/var/log/puppet.log',
  }
}
