# == Class: st2::profile::enterprise_auth_backend_ldap
#
#  Profile to install StackStorm Enterprise Auth Backends. This feature is
#  currently under active development, and limited to early access users.
#  If you would like to try this out, please send an email to support@stackstorm.com
#  and let us know!
#
# === Parameters
#
#  [*version*]      - Version of StackStorm Auth Backend to install
#
# === Variables
#
#  This class has no variables
#
# === Examples
#
#  include ::profile::enterprise_auth_backend
#
class profile::enterprise_auth_backend_ldap(
  $version = '0.1.0',
) inherits st2 {

  $_enterprise_token = hiera('st2enterprise::token', undef)

  $distro_path = $osfamily ? {
    'Debian' => "apt/${lsbdistcodename}",
    'Ubuntu' => "apt/${lsbdistcodename}",
    'RedHat' => "yum/el/${operatingsystemmajrelease}"
  }

  if $_enterprise_token {

    wget::fetch { "Download enterprise auth ldap backend":
      source      => "https://${_enterprise_token}:@downloads.stackstorm.net/st2enterprise/${distro_path}/auth_backends/st2_enterprise_auth_backend_ldap-${version}-py2.7.egg",
      cache_dir   => '/var/cache/wget',
      destination => "/tmp/st2_enterprise_auth_backend_ldap-${version}-py2.7.egg"
    }
  
    exec { 'install auth backend':
      command => "easy_install-2.7 /tmp/st2_enterprise_auth_backend_ldap-${version}-py2.7.egg",
      path    => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin',
      require => Wget::Fetch["Download enterprise auth ldap backend"]
    }
  }
}
