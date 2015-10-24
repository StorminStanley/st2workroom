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
#  $_enterprise_token - StackStorm Enterprise authentication credentials
#  $_ldap_host        - LDAP host to connect to (e.g.: ldap.stackstorm.net)
#  $_ldap_port        - LDAP port to connect to (default: 389)
#  $_ldap_use_ssl     - LDAP Enable SSL (default: false)
#  $_ldap_use_tls     - LDAP Enable TLS (default: false)
#  $_users_ou         - LDAP Base DN (e.g: ou=Users,dc=stackstorm,dc=net)
#  $_id_attr          - LDAP attribute search (default: uid)
#  $_search_scope     - LDAP Search Scope (default: subtree)
#
# === Examples
#
#  include ::profile::enterprise_auth_backend
#
class profile::enterprise_auth_backend_ldap(
  $version = '0.1.0',
) {

  $_enterprise_token = hiera('st2enterprise::token', undef)
  $_ldap_host = hiera('st2::ldap::host', undef)
  $_ldap_port = hiera('st2::ldap::port', 389)
  $_ldap_use_ssl = hiera('st2::ldap::use_ssl', false)
  $_ldap_use_tls = hiera('st2::ldap::use_tls', false)
  $_users_ou = hiera('st2::ldap::base_dn', undef)
  $_id_attr = hiera('st2::ldap::id_attr', 'uid')
  $_scope = hiera('st2::ldap::scope', 'subtree')

  $_host_ip = hiera('system::ipaddress', $::ipaddress)
  $_st2api_port = '9101'
  $_api_url = "https://${_host_ip}:${_st2api_port}"

  # Validations
  validate_bool($_ldap_use_ssl)
  validate_bool($_ldap_use_tls)

  if ! $_ldap_host {
    fail('[st2::ldap] Unknown LDAP Host. Please set st2::ldap::host value in answers file')
  }
  if ! $_users_ou {
    fail('[st2::ldap] Unknown LDAP search base. Please set st2::ldap::users_ou value in answers file')
  }
  if $_ldap_use_ssl and $_ldap_use_tls {
    fail('[st2::ldap] Cannot set both st2::ldap::use_ssl and st2::ldap::use_tls. Please unset one of them')
  }

  $distro_path = $osfamily ? {
    'Debian' => "apt/${lsbdistcodename}",
    'Ubuntu' => "apt/${lsbdistcodename}",
    'RedHat' => "yum/el/${operatingsystemmajrelease}"
  }

  # Only attempt to download new versions of the file, and if I have an enterprise token.
  if $_enterprise_token and $::st2_ldap_backend_version != $version {
    wget::fetch { "Download enterprise auth ldap backend":
      source             => "https://${_enterprise_token}:@downloads.stackstorm.net/st2enterprise/${distro_path}/auth_backends/st2_enterprise_auth_backend_ldap-${version}-py2.7.egg",
      cache_dir          => '/var/cache/wget',
      nocheckcertificate => true,
      destination        => "/tmp/st2_enterprise_auth_backend_ldap-${version}-py2.7.egg"
    }

    exec { 'install enterprise ldap auth backend':
      command => "easy_install-2.7 /tmp/st2_enterprise_auth_backend_ldap-${version}-py2.7.egg",
      path    => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin',
      require => Wget::Fetch["Download enterprise auth ldap backend"]
      before  => Class['::st2::helper::auth_manager'],
    }

    facter::fact { 'st2_ldap_backend_version':
      value => $version,
    }
  }

  # Assemble kwargs
  $_ldap_connection_args = {
    host     => $_ldap_host,
    port     => $_ldap_port,
    users_ou => $_users_ou,
    id_attr  => $_id_attr,
    scope    => $_scope,
  }

  # LDAP SSL Configuration options
  if $_ldap_use_ssl {
    $_ldap_ssl_args = {
      use_ssl => 'True',
    }
  } elsif $_ldap_use_tls {
    $_ldap_ssl_args = {
      use_tls => 'True',
    }
  } else {
    $_ldap_ssl_args = {}
  }
  $_ldap_kwargs = merge($_ldap_connection_args, $_ldap_ssl_args)

  class { '::st2::helper::auth_manager':
    auth_mode      => 'standalone',
    auth_backend   => 'ldap',
    debug          => false,
    syslog         => true,
    backend_kwargs => $_ldap_kwargs,
    api_url        => $_api_url,
  }
}
