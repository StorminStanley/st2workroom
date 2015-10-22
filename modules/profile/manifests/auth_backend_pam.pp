# == Class: st2::profile::auth_backend_pam
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
#  include ::profile::auth_backend_pam
#
class profile::auth_backend_pam(
  $version = '0.1.0',
) inherits st2 {
  $_host_ip = hiera('system::ipaddress', $::ipaddress)
  $_st2api_port = '9101'
  $_api_url = "https://${_host_ip}:${_st2api_port}"

  # TODO: This belongs in a package
  $distro_path = $osfamily ? {
    'Debian' => "apt/${lsbdistcodename}",
    'Ubuntu' => "apt/${lsbdistcodename}",
    'RedHat' => "yum/el/${operatingsystemmajrelease}"
  }

  wget::fetch { "Download auth pam backend":
    source             => "https://downloads.stackstorm.net/st2community/${distro_path}/auth_backends/st2_auth_backend_pam-${version}-py2.7.egg",
    cache_dir          => '/var/cache/wget',
    nocheckcertificate => true,
    destination        => "/tmp/st2_auth_backend_pam-${version}-py2.7.egg"
  }

  exec { 'install pam auth backend':
    command => "easy_install-2.7 /tmp/st2_auth_backend_pam-${version}-py2.7.egg",
    path    => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin',
    require => Wget::Fetch["Download auth pam backend"],
    before  => Class['::st2::profile::server'],
  }

  class { '::st2::helper::auth_manager':
    auth_mode    => 'standalone',
    auth_backend => 'pam',
    debug        => false,
    syslog       => true,
    api_url      => $_api_url,
  }
}
