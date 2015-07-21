class profile::st2server {
  ### Profile Data Collection
  ### Each of these values are values that can be set via Hiera
  ### to configure this class for different environments.
  ### These values are also meant to capture data from st2installer
  ### where applicable.
  $_ssl_cert = '/etc/ssl/st2.crt'
  $_ssl_key = '/etc/ssl/st2.key'
  $_installed = hiera('st2::installer_run', false)
  $_user_ssl_cert = hiera('st2::ssl_public_key', undef)
  $_user_ssl_key = hiera('st2::ssl_private_key', undef)
  $_hostname = hiera('system::hostname', $::fqdn)
  $_host_ip = hiera('system::ipaddress', $::ipaddress)
  $_installer_workroom_mode = hiera('st2::installer_workroom_mode', '0660')
  $_st2auth = hiera('st2::installer_run', false)

  $_server_names = $_st2auth ? {
    true => [
      $_hostname,
      'localhost',
      'st2express.local',
      'localhost.localdomain',
      $_host_ip,
    ],
    default => [
      'localhost',
      'st2express.local',
      'localhost.localdomain',
    ]
  }

  # On first run, rely on the actual services hosted on 0.0.0.0. This
  # is good for packaging in foregin places (a. la: packer), but then
  # lock it down to use the SSL proxy.
  $_st2apiauth_listen_ip = $_installed ? {
    true    => '127.0.0.1',
    default => undef,
  }

  $_api_url = $_installed ? {
    true    => "https://${_host_ip}:9101",
    default => "http://${_host_ip}:9101",
  }

  $_auth_url = $_installed ? {
    true    => "https://${_host_ip}:9100",
    default => "http://${_host_ip}:9100",
  }

  # Ports that uwsgi advertises on 127.0.0.1
  $_st2auth_port = '9100'
  $_st2api_port = '9101'
  $_st2installer_port = '9102'

  # NGINX SSL Settings. Provides A+ Setting. https://cipherli.st
  $_ssl_protocols = 'TLSv1 TLSv1.1 TLSv1.2'
  $_cipher_list = 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:ECDHE-RSA-AES128-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA128:DHE-RSA-AES128-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA128:ECDHE-RSA-AES128-SHA384:ECDHE-RSA-AES128-SHA128:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA384:AES128-GCM-SHA128:AES128-SHA128:AES128-SHA128:AES128-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4'
  $_headers = {
    'Front-End-Https'           => 'on',
    'X-Frame-Options'           => 'DENY',
    'X-Content-Type-Options'    => 'nosniff',
    'Strict-Transport-Security' => '"max-age=63072000; includeSubdomains; preload"',
  }
  $_ssl_options = {
#    'ssl_session_tickets' => 'off',
#    'ssl_stapling'        => 'on',
#    'ssl_stapling_verify' => 'on',
    'resolver'            => '8.8.4.4 8.8.8.8 valid=300s',
    'resolver_timeout'    => '5s',
  }

  #########################################################
  ########## BEGIN RESOURCE DEFINITIONS ###################
  #########################################################

  ### Infrastructure/Application Pre-requsites
  ## nginx-full contains PAM bits
  class { '::nginx':
    package_name => 'nginx-full',
  }

  # We need to grab the group nginx belongs to in order to provide
  # ancillary permissions to specific files. The OS in most cases assigns
  # the daemon user to the same named group. Let's roll with it and
  # see how far it gets us.
  $_nginx_daemon_user = $::nginx::config::daemon_user

  # De-dup code compression without future-parser
  $_st2_classes = [
    "::st2::profile::python",
    "::st2::profile::rabbitmq",
    "::st2::profile::mongodb",
  ]
  include $_st2_classes
  Class[$_st2_classes] -> Anchor['st2::pre_reqs']

  class { '::st2::profile::mistral':
    manage_mysql => true,
    before => Anchor['st2::pre_reqs'],
  }

  # Install StackStorm, after all pre-requsities have been satisifed
  # Use proxy authentication for pam auth, and setup st2api and st2auth
  # listeners on localhost to add SSL reverse proxy via NGINX

  # Authentication is not setup until *after* st2installer is run.
  # Maybe the user doesn't want to change the defaults?! Anyway,
  # doesn't make sense to enable it until then anyway when we have
  # data about the authentication case.

  anchor { 'st2::pre_reqs': }
  -> class { '::st2::profile::client':
    api_url  => $_api_url,
    auth_url => $_auth_url,
  }
  -> class { '::st2::profile::server':
    auth              => $_st2auth,
    st2api_listen_ip  => $_st2apiauth_listen_ip,
    st2auth_listen_ip => $_st2apiauth_listen_ip,
  }
  -> class { '::st2::auth::proxy': }
  -> class { '::st2::profile::web':
    api_url  => $_api_url,
    auth_url => $_auth_url,
  }

  $_python_pack = $::st2::profile::server::_python_pack

  # Manage uwsgi with module, but install it using python pack
  # There is an odd error with installing directly via
  # the `pip` provider when used via Class['uwsgi']
  class { '::uwsgi':
    install_package => false,
    log_rotate      => 'yes',
  }

  python::pip { 'uwsgi':
    ensure  => present,
    before  => Class['::uwsgi'],
  }

  # ### Application Configuration
  # ### Install any and all packs defined in Hiera.
  include ::st2::packs

  ## SSL Certificate
  # Generate a Self-signed cert if the user does not provide cert details
  # This works by controlling the SSL Cert/Key file resources below. If
  # a user provides a key, we pass that content down through to the resource.
  # Otherwise, the cert is generated. Either way, the resources below ensure
  # proper permissioning for the webserver to read/access.
  if $_user_ssl_cert and $_user_ssl_key {
    $_ssl_cert_content = $_user_ssl_cert
    $_ssl_key_content = $_user_key_content
  } else {
    # TODO: Make this configurable with installer.
    # These map directly to the values populated in the below template

    ### This section automatically generates a self-signed CA certificate
    ### using camptocamp/openssl module.
    $_ssl_cert_content = undef
    $_ssl_key_content = undef
    $_ssl_template = '/etc/ssl/st2.cnf'
    $country = 'US'
    $state = 'California'
    $locality = 'Palo Alto'
    $organization = 'StackStorm'
    $unit = 'Information Technology'
    $commonname = $_hostname
    $email = 'support@stackstorm.com'
    $altnames = $_server_names

    file { $_ssl_template:
      ensure  => file,
      owner   => $_nginx_daemon_user,
      mode    => '0444',
      content => template('openssl/cert.cnf.erb'),
    }

    ssl_pkey { $_ssl_key:
      ensure => present,
      before => File[$_ssl_key],
    }

    x509_cert { $_ssl_cert:
      ensure      => present,
      private_key => $_ssl_key,
      template    => $_ssl_template,
      days        => 3650,
      force       => false,
      require     => [
        Ssl_pkey[$_ssl_key],
        File[$_ssl_template],
      ],
      before      => File[$_ssl_cert],
    }
  }

  # Ensure the SSL Certificates are owned by the proper
  # group to be readable by NGINX.
  # This relies on the NGINX daemon user belonging to the shadow
  # group, given that this is also necessary for PAM access, gives
  # a tidy way to keep permissions limited.
  file { $_ssl_cert:
    ensure  => file,
    owner   => 'root',
    mode    => '0444',
    content => $_ssl_cert_content,
  }
  file { $_ssl_key:
    ensure  => file,
    owner   => 'root',
    mode    => '0440',
    content => $_ssl_key_content,
  }

  # Configure NGINX WebUI on 443
  nginx::resource::vhost { 'st2webui':
    ensure            => present,
    listen_port       => '443',
    ssl               => true,
    ssl_cert          => $_ssl_cert,
    ssl_key           => $_ssl_key,
    ssl_protocols     => $_ssl_protocols,
    ssl_ciphers       => $_cipher_list,
    vhost_cfg_prepend => $_ssl_options,
    server_name       => $_server_names,
    add_header        => $_headers,
    www_root          => '/opt/stackstorm/static/webui/',
    require           => X509_cert[$_ssl_cert],
  }

  file_line { 'st2 disable simple HTTP server':
    path => '/etc/environment',
    line => 'ST2_DISABLE_HTTPSERVER=true',
  }

  ## st2auth and st2api SSL proxies via nginx
  $_st2api_custom_options = "if (\$request_method = 'OPTIONS') {
			add_header 'Access-Control-Allow-Origin' '*';
			add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
	 		add_header 'Access-Control-Allow-Headers' 'x-auth-token,DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
			add_header 'Access-Control-Max-Age' 1728000;
			add_header 'Content-Type' 'text/plain charset=UTF-8';
			add_header 'Content-Length' 0;

			return 204;
		 }"

  # Note this is in a flag. On first installation, nginx proxy
  # with SSL is not available
  if $_installed {
    nginx::resource::vhost { 'st2api':
      ensure               => present,
      listen_ip            => $_host_ip,
      listen_port          => 9101,
      ssl                  => true,
      ssl_port             => 9101,
      ssl_cert             => $_ssl_cert,
      ssl_key              => $_ssl_key,
      ssl_protocols        => $_ssl_protocols,
      ssl_ciphers          => $_cipher_list,
      server_name          => $_server_names,
      vhost_cfg_prepend    => $_ssl_options,
      proxy                => 'http://st2api',
      proxy_set_header     => [
        'Host $host',
        "Connection ''",
      ],
      location_raw_prepend => [
        $_st2api_custom_options,
      ],
      location_raw_append  => [
        'proxy_http_version 1.1;',
        'chunked_transfer_encoding off;',
        'proxy_buffering off;',
        'proxy_cache off;',
      ],
      notify              => Service['st2api'],
    }

    nginx::resource::upstream { 'st2api':
      members => ["127.0.0.1:${_st2api_port}"],
    }
  }

  # Note this is in a flag. By default on first installation, authentication
  # is not enabled. This allows for things like packs to install cleanly,
  # and not be burdensome. It's a basic installation. If a user wants
  # to take the experience and customize it for them, then auth
  # will be enabled once the st2installer runs.
  if $_st2auth {
    # ## Authentication
    # ### Nginx needs access to make calls to PAM, and by
    # ### extension, needs access to /etc/shadow to validate users.
    # ### Let's at least try to do this safely and consistently

    # Let's add our nginx user to the `shadow` group, but do
    # it after the package manager has installed and setup
    # the user
    user { $_nginx_daemon_user:
      groups  => ['shadow'],
    }

    pam::service { 'nginx':
      content => '@include common-auth',
    }

    nginx::resource::vhost { 'st2auth':
      ensure               => present,
      listen_ip            => $_host_ip,
      listen_port          => 9100,
      ssl                  => true,
      ssl_port             => 9100,
      ssl_cert             => $_ssl_cert,
      ssl_key              => $_ssl_key,
      ssl_protocols        => $_ssl_protocols,
      ssl_ciphers          => $_cipher_list,
      vhost_cfg_prepend    => $_ssl_options,
      server_name          => $_server_names,
      location_raw_prepend => [
        'auth_pam "Restricted";',
        'auth_pam_service_name "nginx";',
      ],
      proxy                => 'http://st2auth',
      proxy_set_header     => [
        'Host $host',
        'X-Real-IP $remote_addr',
        'X-Forwarded-For $proxy_add_x_forwarded_for',
      ],
      location_raw_append => [
        'proxy_pass_header Authorization;',
      ],
    }

    nginx::resource::upstream { 'st2auth':
      members => ["127.0.0.1:${_st2auth_port}"],
    }
  }

  # Setup the installer on initial provision, and get rid of it
  # after setup has been run.
  if ! $_installed {
    vcsrepo { '/opt/stackstorm/st2installer':
      ensure   => present,
      provider => 'git',
      source   => 'https://github.com/stackstorm/st2installer',
      require  => Class['::st2::profile::server'],
    }

    uwsgi::app { 'st2installer':
      ensure              => present,
      uid                 => $_nginx_daemon_user,
      gid                 => $_nginx_daemon_user,
      application_options => {
        'http-socket'  => "127.0.0.1:${_st2installer_port}",
        'processes'    => 1,
        'threads'      => 10,
        'pecan'        => 'app.wsgi',
        'chdir'        => '/opt/stackstorm/st2installer',
        'vacuum'       => true,
      },
      require       => Vcsrepo['/opt/stackstorm/st2installer'],
    }

    nginx::resource::location { 'st2installer':
      vhost               => 'st2webui',
      ssl_only            => true,
      location            => '/setup/',
      proxy               => 'http://st2installer',
      rewrite_rules       => [
        '^/setup/(.*)  /$1 break',
      ],
    }

    nginx::resource::upstream { 'st2installer':
      members => ["127.0.0.1:${_st2installer_port}"],
    }

    ### Installer needs access to a few specific files
    file { "${::settings::confdir}/hieradata/workroom.yaml":
      ensure => file,
      owner  => $_nginx_daemon_user,
      group  => $_nginx_daemon_user,
      mode   => $_installer_workroom_mode,
    }

    file { '/tmp/st2installer.log':
      ensure => file,
      owner  => $_nginx_daemon_user,
      group  => $_nginx_daemon_user,
      mode   => $_installer_workroom_mode,
    }

    ### Installer also needs the ability to kick off a Puppet run to converge the system
    sudo::conf { "env_puppet":
      priority => '5',
      content  => 'Defaults!/usr/bin/puprun env_keep += "nocolor environment debug"',
    }

    sudo::conf { $_nginx_daemon_user:
      priority => '10',
      content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/bin/puprun",
    }
  }
}
