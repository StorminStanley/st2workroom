class profile::st2server {
  ### Profile Data Collection
  $_ssl_cert = '/etc/ssl/st2.crt'
  $_ssl_key = '/etc/ssl/st2.key'
  $_user_ssl_cert = hiera('st2::ssl_public_key', undef)
  $_user_ssl_key = hiera('st2::ssl_private_key', undef)
  $_hostname = hiera('system::hostname', $::fqdn)
  $_host_ip = hiera('system::ipaddress', $::ipaddress)
  $_st2auth_processes = hiera('st2::auth_processes', 2)
  $_st2auth_threads = hiera('st2::auth_threads', 25)
  $_st2api_processes = hiera('st2::api_processes', 2)
  $_st2api_threads = hiera('st2::api_threads', 25)
  $_st2auth_socket = '/var/run/st2auth.sock'
  $_st2api_socket = '/var/run/st2api.sock'

  # NGINX SSL Settings. Provides A+ Setting. https://cipherli.st
  $_ssl_protocols = 'TLSv1 TLSv1.1 TLSv1.2'
  $_cipher_list = 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:ECDHE-RSA-AES128-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA128:DHE-RSA-AES128-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA128:ECDHE-RSA-AES128-SHA384:ECDHE-RSA-AES128-SHA128:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA384:AES128-GCM-SHA128:AES128-SHA128:AES128-SHA128:AES128-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4'
  $_headers = {
    'Front-End-Https'           => 'on',
    'X-Frame-Options'           => 'DENY',
    'X-Content-Type-Options'    => 'nosniff',
    'Strict-Transport-Security' => '"max-age=63072000; includeSubdomains; preload"',
  }
  $_ssl_options = [
    'ssl_session_tickets off;',
    'ssl_stapling on;',
    'ssl_stapling_verify on;',
    'resolver 8.8.4.4 8.8.8.8 valid=300s;',
    'resolver_timeout 5s;',
  ]

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
  # Use proxy authentication for pam auth.
  anchor { 'st2::pre_reqs': }
  -> class { '::st2::profile::client': }
  -> class { '::st2::profile::server': }
  -> class { '::st2::auth::proxy': }
  -> class { '::st2::profile::web': }

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
    $altnames = ['localhost', 'localhost.localdomain', 'st2express.local', 'st2express', $_host_ip]

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

  # # Configure NGINX WebUI on 443
  nginx::resource::vhost { 'st2webui':
    ensure        => present,
    listen_port   => '443',
    ssl           => true,
    ssl_cert      => $_ssl_cert,
    ssl_key       => $_ssl_key,
    ssl_protocols => $_ssl_protocols,
    ssl_ciphers   => $_cipher_list,
    raw_prepend   => $_ssl_options,
    server_name   => [
      $_hostname,
      'st2express.local',
      'localhost.localdomain',
      $_host_ip,
    ],
    add_header    => $_headers,
    www_root      => '/opt/stackstorm/static/webui/',
    require       => X509_cert[$_ssl_cert],
  }

  ## st2auth and st2api SSL proxies via nginx

  ### Shared proxy headers for each reverse proxy
  nginx::resource::vhost { 'st2api':
    ensure               => present,
    ssl                  => true,
    ssl_port             => 9101,
    ssl_cert             => $_ssl_cert,
    ssl_key              => $_ssl_key,
    ssl_protocols        => $_ssl_protocols,
    ssl_ciphers          => $_cipher_list,
    raw_append           => $_ssl_options,
    use_default_location => false,
    vhost_cfg_prepend    => {
      'charset' => 'utf-8',
    },
  }

  nginx::resource::location { 'st2api-uwsgi':
    vhost               => 'st2api',
    location            => '/',
    location_custom_cfg => {
      'uwsgi_pass'  => 'st2auth',
      'include'     => 'uwsgi_params',
    },
  }

  file { $_st2api_socket:
    ensure => present,
    owner  => $_nginx_daemon_user,
    group  => $_nginx_daemon_user,
  }

  nginx::resource::upstream { 'st2api':
    ensure  => present,
    members => ["unix:///${_st2api_socket}"],
  }

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

  uwsgi::app { 'st2auth':
    ensure              => present,
    uid                 => $_nginx_daemon_user,
    gid                 => $_nginx_daemon_user,
    application_options => {
      'socket'    => $_st2auth_socket,
      'processes' => $_st2auth_processes,
      'threads'   => $_st2auth_threads,
      'wsgi-file' => "${_python_pack}/st2auth/wsgi.py",
      'plugins'   => 'python',
      'logto'     => '/var/log/uwsgi/st2auth.log',
    }
  }

  nginx::resource::vhost { 'st2auth':
    ensure               => present,
    ssl                  => true,
    ssl_port             => 9100,
    ssl_cert             => $_ssl_cert,
    ssl_key              => $_ssl_key,
    ssl_protocols        => $_ssl_protocols,
    ssl_ciphers          => $_cipher_list,
    raw_append           => $_ssl_options,
    location_raw_prepend => [
      'auth_pam "Restricted";',
      'auth_pam_service_name "nginx";',
    ],
    use_default_location => false,
    vhost_cfg_prepend    => {
      'charset' => 'utf-8',
    },
  }

  nginx::resource::location { 'st2auth-uwsgi':
    vhost               => 'st2auth',
    location            => '/',
    location_custom_cfg => {
      'uwsgi_pass'  => 'st2auth',
      'include'     => 'uwsgi_params',
    },
  }

  file { $_st2auth_socket:
    ensure => present,
    owner  => $_nginx_daemon_user,
    group  => $_nginx_daemon_user,
  }

  nginx::resource::upstream { 'st2auth':
    ensure  => present,
    members => ["unix:///${_st2auth_socket}"],
  }

  # # # Setup the installer on initial provision, and get rid of it
  # # # after setup has been run.
  # # if $_installer {

  # # } else {

  # # }
}
