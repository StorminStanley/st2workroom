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

  file { '/opt/stackstorm/static/webui/flow':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  $_bootstrapped = $::st2flow_bootstrapped ? {
    undef   => false,
    default => str2bool($::st2flow_bootstrapped),
  }

  $_access_key = hiera('aws::access_key', undef)
  $_secret_key = hiera('aws::secret_access_key', undef)

  if $_access_key and $_secret_key {
    class {'s3cmd':
      aws_access_key => $_access_key,
      aws_secret_key => $_secret_key,
      gpg_passphrase => fqdn_rand_string(32),
      owner          => 'root',
    }
    s3cmd::commands::get { '/tmp/flow.tar.gz':
      s3_object => "s3://st2flow/flow-${st2::version}.tar.gz",
      cwd       => '/tmp',
      owner     => 'root',
      require   => Class['s3cmd'],
    }
  }
  
  exec { 'extract flow':
    command => 'tar -xzvf /tmp/flow.tar.gz -C /opt/stackstorm/static/webui/flow --strip-components=1 --owner root --group root --no-same-owner',
    creates => '/opt/stackstorm/static/webui/flow/index.html',
    path    => '/usr/bin:/usr/sbin:/bin:/sbin',
    require => [
      File['/opt/stackstorm/static/webui/flow'],
      S3cmd::Commands::Get['/tmp/flow.tar.gz']
    ],
  }

  file { '/etc/facter/facts.d/st2flow_bootstrapped.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => Exec['extract flow'],
    content => 'st2flow_bootstrapped=true',
  }

}
