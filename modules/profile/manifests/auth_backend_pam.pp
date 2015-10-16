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

  $distro_path = $osfamily ? {
    'Debian' => "apt/${lsbdistcodename}",
    'Ubuntu' => "apt/${lsbdistcodename}",
    'RedHat' => "yum/el/${operatingsystemmajrelease}"
  }

  wget::fetch { "Download auth pam backend":
    source      => "https://downloads.stackstorm.net/st2community/${distro_path}/auth_backends/st2_auth_backend_pam-${version}-py2.7.egg",
    cache_dir   => '/var/cache/wget',
    destination => "/tmp/st2_auth_backend_pam-${version}-py2.7.egg"
  }

  exec { 'install auth backend':
    command => "easy_install-2.7 /tmp/st2_auth_backend_pam-${version}-py2.7.egg",
    path    => '/usr/bin:/usr/sbin:/bin:/sbin',
    require => Wget::Fetch["Download auth pam backend"]
  }

}
