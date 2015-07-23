class puppet::masterless(
  $cron        = true,
  $run_at_boot = false,
  $version     = $::puppet::version,
) inherits puppet {
  $offset = fqdn_rand(30)

  package { 'puppet-agent':
    ensure => "${version}-1${::lsbdistcodename}",
  }

  file { '/usr/bin/facter':
    ensure => symlink,
    target => '/opt/puppetlabs/bin/facter',
  }
  file { '/usr/bin/puppet':
    ensure => symlink,
    target => '/opt/puppetlabs/bin/puppet',
  }

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

  file { '/usr/bin/puprun':
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

  service { ['puppet', 'mcollective']:
    ensure     => stopped,
    enable     => false,
    hasstatus  => true,
    hasrestart => true,
  }
}
