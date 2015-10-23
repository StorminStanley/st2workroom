# == Class: st2::profile::st2flow
#
#  Profile to install StackStorm graphical workflow designer. This feature is
#  currently under active development, and limited to early access users.
#  If you would like to try this out, please send an email to support@stackstorm.com
#  and let us know!
#
# === Parameters
#
#  [*version*]      - Version of StackStorm Flow to install
#
# === Variables
#
#  This class has no variables
#
# === Examples
#
#  include ::profile::st2flow
#
class profile::st2flow(
  $version = $::st2::version
) inherits st2 {
  $_enterprise_token = hiera('st2enterprise::token', undef)
  if $_enterprise_token and $::st2flow_version != $version {
    file { '/opt/stackstorm/static/webui/flow':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    $distro_path = $osfamily ? {
      'Debian' => "apt/${lsbdistcodename}",
      'Ubuntu' => "apt/${lsbdistcodename}",
      'RedHat' => "yum/el/${operatingsystemmajrelease}"
    }

    wget::fetch { 'Download Flow artifact':
      source             => "https://${_enterprise_token}:@downloads.stackstorm.net/st2enterprise/${distro_path}/st2flow/flow-${st2::version}.tar.gz",
      cache_dir          => '/var/cache/wget',
      destination        => '/tmp/flow.tar.gz',
      nocheckcertificate => true,
      before             => Exec['extract flow'],
    }

    exec { 'extract flow':
      command => 'tar -xzvf /tmp/flow.tar.gz -C /opt/stackstorm/static/webui/flow --strip-components=1 --owner root --group root --no-same-owner',
      creates => '/opt/stackstorm/static/webui/flow/index.html',
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      require => File['/opt/stackstorm/static/webui/flow'],
    }
  }

  facter::fact { 'st2flow_version':
    value => $version,
  }
}
