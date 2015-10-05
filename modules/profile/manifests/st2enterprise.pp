class profile::st2enterprise {
  $_enable_enterprise_banner = hiera('st2::enterprise::banner', false)

  # Set /etc/issue banner for Appliance Installs
  if $_enable_enterprise_banner {
    ## Show IP Address at Boot
    if $::osfamily == 'Debian' {
      file { '/etc/network/if-up.d/st2enterprise-etc-issue':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/st2enterprise/st2enterprise-etc-issue',
      }
    }
  }
}
