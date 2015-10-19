class profile::vagrant {
  $_packages = $::osfamily ? {
    'Debian' => ['avahi-daemon', 'vim', 'software-properties-common', 'zsh'],
    'RedHat' => ['avahi'],
  }

  package { $_packages:
    ensure => present,
  }

  service { 'avahi-daemon':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  sudo::conf { 'vagrant':
    ensure  => present,
    content => '%vagrant ALL=(ALL) NOPASSWD: ALL',
  }

  # Often, the fact that the node belongs to Vagrant is told
  # on first boot. Hovewer, subsequent runs of Puppet in this
  # environment on the box iteslf (via installer or update-system)
  # should retain this knowledge.
  file { '/etc/facter/facts.d/datacenter.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => 'datacenter=vagrant',
  }

  file_line { 'disable_tty':
    path  => '/etc/sudoers',
    match => 'Defaults    requiretty',
    line  => '## Defaults    requiretty',
  }
}
