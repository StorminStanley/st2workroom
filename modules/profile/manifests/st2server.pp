class profile::st2server {
  ### Profile Data Collection
  ### Each of these values are values that can be set via Hiera
  ### to configure this class for different environments.
  ### These values are also meant to capture data from st2installer
  ### where applicable.
  $_ssl_cert = '/etc/ssl/st2.crt'
  $_ssl_key = '/etc/ssl/st2.key'
  $_user_ssl_cert = hiera('st2::ssl_public_key', undef)
  $_user_ssl_key = hiera('st2::ssl_private_key', undef)
  $_hostname = hiera('system::hostname', $::hostname)
  $_fqdn = hiera('system::fqdn', $::fqdn)
  $_host_ip = hiera('system::ipaddress', $::ipaddress_eth0)
  $_installer_workroom_mode = hiera('st2::installer_workroom_mode', '0660')
  $_st2auth_uwsgi_threads = hiera('st2::auth_uwsgi_threads', 10)
  $_st2auth_uwsgi_processes = hiera('st2::auth_uwsgi_processes', 1)
  $_st2api_uwsgi_threads = hiera('st2::api_uwsgi_threads', 10)
  $_st2api_uwsgi_processes = hiera('st2::api_uwsgi_processes', 1)
  $_st2installer_branch = hiera('st2::installer_branch', 'stable')
  $_mistral_uwsgi_threads = hiera('st2::mistral_uwsgi_threads', 25)
  $_mistral_uwsgi_processes = hiera('st2::mistral_uwsgi_processes', 1)
  $_installer_lockdown = hiera('st2::installer::lockdown', false)
  $_installer_username = hiera('st2::installer::username', 'installer')
  $_installer_password = hiera('st2::installer::password', fqdn_rand_string(32))
  $_root_cli_username = 'root_cli'
  $_root_cli_password = fqdn_rand_string(32)
  $_root_cli_uid = 2000
  $_root_cli_gid = 2000

  # Need to determine the state of the Installer for purposes of User management.
  # Users and their corresponding SSH keys only need to be created during the
  # installer process. Any other management of these values may end up in
  # unnecessary overwriting of passwords/keys/etc.
  $_installer_running = hiera('st2::installer_run', false)
  $_installer_run = $::st2_installer_run

  if $_installer_running {
    file { '/etc/facter/facts.d/st2_installer_run.txt':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => 'st2_installer_run=true',
    }
  }

  # In the event that we are packaging an image to be used 100% offline
  # this flag exists to wrap any resource that may automatically update
  # or make an external call to the internet. This avoids that, instead
  # relying on the first-run packaging to have done the needful.
  #
  # We assume by default that the user has internet access, but this
  # is not always the case (restricted VPC or images we want to otherwise
  # freeze).
  $_autoupdate = hiera('st2::autoupdate', true)

  if $_user_ssl_cert and $_user_ssl_key {
    $_self_signed_cert = false
  } else {
    $_self_signed_cert = true
  }

  $_server_names = [
    $_hostname,
    $_fqdn,
    $_host_ip,
  ]

  # Ports that uwsgi advertises on 127.0.0.1
  $_st2auth_socket = '/tmp/st2auth.sock'
  $_st2api_socket = '/tmp/st2api.sock'
  $_st2installer_socket = '/tmp/st2installer.sock'
  $_mistral_socket = '/tmp/mistral.sock'
  $_mistral_port = '8989'
  $_st2auth_port = '9100'
  $_st2api_port = '9101'
  $_st2installer_port = '9102'
  $_api_url = "https://${_hostname}:${_st2api_port}"
  $_auth_url = "https://${_hostname}:${_st2auth_port}"
  $_mistral_url = $_hostname

  $_st2installer_root = '/etc/st2installer'
  $_st2installer_logfile = '/var/log/st2/st2installer.log'
  $_mistral_logfile = '/var/log/mistral-api.log'

  ## Application Directories. A tight coupling, but ok because it's a profile

  # NGINX SSL Settings. Provides A+ Setting. https://cipherli.st
  $_ssl_protocols = 'TLSv1 TLSv1.1 TLSv1.2'
  $_cipher_list = 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:ECDHE-RSA-AES128-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA128:DHE-RSA-AES128-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA128:ECDHE-RSA-AES128-SHA384:ECDHE-RSA-AES128-SHA128:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA384:AES128-GCM-SHA128:AES128-SHA128:AES128-SHA128:AES128-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4'

  # Disable HSTS if the user provides a self-signed cert
  $_headers = $_self_signed_cert ? {
    true => {
      'Front-End-Https'           => 'on',
      'X-Content-Type-Options'    => 'nosniff',
    },
    default => {
      'Front-End-Https'           => 'on',
      'X-Content-Type-Options'    => 'nosniff',
      'Strict-Transport-Security' =>
        '"max-age=63072000; includeSubdomains; preload"',
    }
  }

  #########################################################
  ########## BEGIN RESOURCE DEFINITIONS ###################
  #########################################################

  ### Breadcrumbs
  ## Leave a breadcrumb if need to get data outside of Puppet. Do it via Facter
  file { '/etc/facter/facts.d/st2_ip.txt':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => "st2_ip=${_host_ip}",
  }

  ### Infrastructure/Application Pre-requsites

  ## Note: nginx-full contains PAM bits
  ## Note: Service restart is setup this way to prevent puppet runs from
  ##       triggering a restart. Instead, nginx restart must be executed
  ##       manually by the user
  $_nginx_configtest = $::installer_running ? {
    undef   => undef,
    default => true,
  }

  class { '::nginx':
    package_name      => 'nginx-full',
    service_restart   => '/etc/init.d/nginx configtest',
    configtest_enable => $_nginx_configtest,
  }

  # We need to grab the group nginx belongs to in order to provide
  # ancillary permissions to specific files. The OS in most cases assigns
  # the daemon user to the same named group. Let's roll with it and
  # see how far it gets us.
  $_nginx_daemon_user = $::nginx::config::daemon_user

  # De-dup code compression without future-parser
  $_st2_classes = [
    '::st2::profile::python',
    '::profile::rabbitmq',
    '::profile::mongodb',
  ]
  include $_st2_classes
  Class[$_st2_classes] -> Anchor['st2::pre_reqs']

  # In the event that we are in offline mode, detach all downstream dependencies
  # as the vcsrepo action failing will cause all downsteam dependencies to fail.
  # It is safe to assume the requirements have been met at the time of run
  $_st2_profile_mistral_before = $_autoupdate ? {
    true    => Anchor['st2::pre_reqs'],
    default => undef,
  }
  class { '::st2::profile::mistral':
    manage_postgresql => true,
    api_url           => $_mistral_url,
    api_port          => $_mistral_port,
    disable_api       => true,
    before            => $_st2_profile_mistral_before,
  }
  # $_mistral_root needs to be loaded here due to load-order
  $_mistral_root = $::st2::profile::mistral::_mistral_root

  # Install StackStorm, after all pre-requsities have been satisifed
  # Use proxy authentication for pam auth, and setup st2api and st2auth
  # listeners on localhost to add SSL reverse proxy via NGINX

  # Authentication is not setup until *after* st2installer is run.
  # Maybe the user doesn't want to change the defaults?! Anyway,
  # doesn't make sense to enable it until then anyway when we have
  # data about the authentication case.

  # Because we now use PAM based authentication, we need credentials
  # for the root user. That isn't quite so easy, because we're not
  # managing the root user password, nor can we re-set the password
  # for the automatically generated `puppet` user when used with "standalone"
  # auth. For this, we'll leverage the existing Users defined type
  # to create the account to be used by the System root user. It's a bit
  # meta gross, but it's the cleanest way without knowing what environment
  # this installer will pop up in.

  if ! $_installer_run {
    users { $_root_cli_username:
      uid        => $_root_cli_uid,
      gid        => $_root_cli_gid,
      shell      => '/bin/false',
      password   => $_root_cli_password,
      managehome => false,
    }
  }

  anchor { 'st2::pre_reqs': }
  -> class { '::st2::profile::client':
    username    => $_root_cli_username,
    password    => $_root_cli_password,
    api_url     => $_api_url,
    auth_url    => $_auth_url,
    cache_token => false,
  }
  -> class { '::st2::profile::server':
    auth                   => true,
    st2api_listen_ip       => '127.0.0.1',
    manage_st2auth_service => false,
    manage_st2web_service  => false,
    syslog                 => true,
  }
  -> class { '::st2::auth::proxy': }
  -> class { '::st2::profile::web':
    api_url  => "https://:${_st2api_port}",
    auth_url => "https://:${_st2auth_port}",
  }

  # Only manage the ::st2::stanley admin account
  # when the installer has either not run (managed in workroom.yaml)
  # or when the installer is or has ran (managed in answers.yaml)
  #
  # Answers.yaml is deleted by the st2installer after run to prevent
  # credential leakage. To that end, if this class still is being managed
  # and no hiera data exists, SSH keys and the admint account will be
  # overwritten with default values, and this is undesirable.
  if ! $_installer_run {
    include ::st2::stanley
  }

  include ::st2::logging::rsyslog

  # $_python_pack needs to be loaded here due to load-order
  $_python_pack = $::st2::profile::server::_python_pack

  # Manage uwsgi with module, but install it using python pack
  # There is an odd error with installing directly via
  # the `pip` provider when used via Class['uwsgi']
  #
  # This class also disables the emperor service. To that end
  # to manage a service for StackStorm, you must use the
  # adapter::st2_uwsgi_service to start uwsgi services that
  # will be proxied to nginx.
  class { '::uwsgi':
    install_package => false,
    log_rotate      => 'yes',
    service_ensure  => false,
    service_enable  => false,
  }

  python::pip { 'uwsgi':
    ensure => present,
    before => Class['::uwsgi'],
  }

  # ### Application Configuration
  # ### Install any and all packs defined in Hiera.
  include ::st2::packs
  include ::st2::kvs

  ## Because authentication is now being passed via Nginx, we need to make sure that
  ## the service for nginx is up and running before responding to any CLI requests
  Service['nginx'] -> Exec['restart st2'] -> Exec<| tag == 'st2::kv' |>
  Service['nginx'] -> Exec['restart st2'] -> Exec<| tag == 'st2::pack' |>

  ## SSL Certificate
  # Generate a Self-signed cert if the user does not provide cert details
  # This works by controlling the SSL Cert/Key file resources below. If
  # a user provides a key, we pass that content down through to the resource.
  # Otherwise, the cert is generated. Either way, the resources below ensure
  # proper permissioning for the webserver to read/access.
  if ! $_self_signed_cert {
    $_ssl_cert_content = $_user_ssl_cert
    $_ssl_key_content = $_user_ssl_key
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
      notify  => Exec['remove old self-signed certs'],
    }

    # In the event that the configuration is refreshed, clean
    # up the old certificates to prevent cert mismatches and
    # CORS errors
    exec { 'remove old self-signed certs':
      command => "rm -rf ${_ssl_key} ${_ssl_cert}",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      refreshonly => true,
      before      => [
        Ssl_pkey[$_ssl_key],
        X509_cert[$_ssl_cert],
      ],
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
    notify  => Class['::nginx::service'],
  }
  file { $_ssl_key:
    ensure  => file,
    owner   => 'root',
    mode    => '0440',
    content => $_ssl_key_content,
    notify  => Class['::nginx::service'],
  }

  ## Add the certificate to the trusted root store to get rid
  ## of annoying issues related to self-signed or trusted
  file { '/usr/local/share/ca-certificates/st2':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/usr/local/share/ca-certificates/st2/st2_trusted_cert.crt':
    ensure  => file,
    owner   => 'root',
    mode    => '0444',
    source  => $_ssl_cert,
    require => File[$_ssl_cert],
    notify  => Exec['update-ca-certificates'],
  }
  exec { 'update-ca-certificates':
    command     => 'update-ca-certificates',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true,
  }

  ## Mistral uWSGI
  ## This creates the init script to start the
  ## mistral api service via uwsgi
  adapter::st2_uwsgi_init { 'mistral': }

  # File permissions to allow uWSGI process to write logs
  file { $_mistral_logfile:
    ensure => file,
    owner  => $_nginx_daemon_user,
    group  => $_nginx_daemon_user,
    mode   => '0664',
  }

  uwsgi::app { 'mistral-api':
    ensure              => present,
    uid                 => $_nginx_daemon_user,
    gid                 => $_nginx_daemon_user,
    application_options => {
      'socket'       => $_mistral_socket,
      'processes'    => $_mistral_uwsgi_processes,
      'threads'      => $_mistral_uwsgi_threads,
      'home'         => "${_mistral_root}/.venv/",
      'wsgi-file'    => "${_mistral_root}/mistral/api/wsgi.py",
      'vacuum'       => true,
      'logto'        => $_mistral_logfile,
      'chmod-socket' => '644',
    },
    notify              => Service['mistral-api'],
  }

  nginx::resource::vhost { 'mistral-api':
    ensure               => present,
    listen_port          => $_mistral_port,
    # Disabling SSL temporarily while changes ported in
    # JDF - 20150804
    # ssl                  => true,
    # ssl_port             => $_mistral_port,
    # ssl_cert             => $_ssl_cert,
    # ssl_key              => $_ssl_key,
    # ssl_protocols        => $_ssl_protocols,
    # ssl_ciphers          => $_cipher_list,
    server_name          => $_server_names,
    uwsgi                => "unix://${_mistral_socket}",
  }

  # Cheating here a little bit. Because the st2web is now being
  # served via nginx/HTTPS, the SimpleHTTPServer is no longer needed
  # Only problem is, if there is not a service named `st2web`, `st2ctl`
  # ceases to work. Can't have that.
  #
  # st2actionrunner is a dummy resource already that is used as an anchor
  # for the st2actionrunner-workerN resources, pre-populated by Puppet based
  # on the total number of workers. Well, it won't hurt to re-use the
  # same dummy anchor resource here.
  #
  # This is a pretty tight coupling to the st2 puppet module for right now.
  # TODO Fix when it makes sense and it has a home.
  file { '/etc/init/st2web.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/st2/etc/init/st2actionrunner.conf',
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
    server_name       => $_server_names,
    add_header        => $_headers,
    www_root          => '/opt/stackstorm/static/webui/',
    subscribe         => File[$_ssl_cert],
  }

  # Flag set in st2ctl to prevent the SimpleHTTPServer from starting. This
  # should not be necessary with init scripts, but here just in case.
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

  nginx::resource::vhost { 'st2api':
    ensure               => present,
    listen_ip            => $_host_ip,
    listen_port          => $_st2api_port,
    ssl                  => true,
    ssl_port             => $_st2api_port,
    ssl_cert             => $_ssl_cert,
    ssl_key              => $_ssl_key,
    ssl_protocols        => $_ssl_protocols,
    ssl_ciphers          => $_cipher_list,
    server_name          => $_server_names,
    proxy                => 'http://st2api',
    location_raw_prepend => [
      $_st2api_custom_options,
    ],
    location_raw_append => [
      "proxy_set_header Connection '';",
      'proxy_http_version 1.1;',
      'chunked_transfer_encoding off;',
      'proxy_buffering off;',
      'proxy_cache off;',
      'proxy_set_header Host $host;',
    ],
  }

  nginx::resource::upstream { 'st2api':
    members => ["127.0.0.1:${_st2api_port}"],
  }

  # ## Authentication
  # ### Nginx needs access to make calls to PAM, and by
  # ### extension, needs access to /etc/shadow to validate users.
  # ### Let's at least try to do this safely and consistently

  $_st2auth_custom_options = 'limit_except OPTIONS {
			auth_pam "Restricted";
      auth_pam_service_name "nginx";
		}'

  # Let's add our nginx user to the `shadow` group, but do
  # it after the package manager has installed and setup
  # the user
  user { $_nginx_daemon_user:
    groups  => ['shadow'],
  }

  pam::service { 'nginx':
    content => '@include common-auth',
  }

  ## This creates the init script to start the
  ## st2auth service via uwsgi
  adapter::st2_uwsgi_init { 'st2auth': }

  # File permissions to allow uWSGI process to write logs
  File<| title == '/var/log/st2/st2auth.log' |> {
    owner  => $_nginx_daemon_user,
  }

  uwsgi::app { 'st2auth':
    ensure              => present,
    uid                 => $_nginx_daemon_user,
    gid                 => $_nginx_daemon_user,
    application_options => {
      'socket'       => $_st2auth_socket,
      'processes'    => $_st2auth_uwsgi_processes,
      'threads'      => $_st2auth_uwsgi_threads,
      'wsgi-file'    => "${_python_pack}/st2auth/wsgi.py",
      'vacuum'       => true,
      'logto'        => '/var/log/st2/st2auth.log',
      'chmod-socket' => '644',
    },
    notify             => Service['st2auth'],
  }

  nginx::resource::vhost { 'st2auth':
    ensure               => present,
    listen_port          => $_st2auth_port,
    ssl                  => true,
    ssl_port             => $_st2auth_port,
    ssl_cert             => $_ssl_cert,
    ssl_key              => $_ssl_key,
    ssl_protocols        => $_ssl_protocols,
    ssl_ciphers          => $_cipher_list,
    server_name          => $_server_names,
    uwsgi                => "unix://${_st2auth_socket}",
    proxy_set_header     => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
    ],
    location_raw_append => [
      'proxy_pass_header Authorization;',
      'uwsgi_param  REMOTE_USER        $remote_user;',
      $_st2auth_custom_options,
    ],
  }

  # Needed for uWSGI server to write to logs
  file { [
    '/var/log/st2/st2api.log',
    '/var/log/st2/st2api.audit.log',
    '/var/log/st2/st2auth.log',
    '/var/log/st2/st2auth.audit.log',
  ]:
    ensure  => present,
    owner   => $_nginx_daemon_user,
    group   => $_nginx_daemon_user,
    mode    => '0664',
    require => Class['::st2::profile::server'],
    before  => Adapter::St2_uwsgi_init['st2auth'],
  }

  # Ensure that the st2auth service is started up and serving before
  # attempting to download anything
  Class['::st2::profile::server'] -> Class['::nginx::service'] -> St2::Pack<||>

  # Setup the installer on initial provision, and get rid of it
  # after setup has been run.

  $_st2installer_before = $_autoupdate ? {
    true    => Uwsgi::App['st2installer'],
    default => undef,
  }

  # In some environments, the Installer must be locked down to prevent
  # it from being run by a bad actor on a public machine. If this is true,
  # then create an htaccess file, and apply it to the installer endpoint
  if $_installer_lockdown {
    $_auth_file = "${_st2installer_root}/.htaccess"
    $_st2installer_auth_basic = "StackStorm Installer"
    $_st2installer_auth_basic_user_file = $_auth_file

    httpauth { $_installer_username:
      ensure    => present,
      file      => $_auth_file,
      password  => $_installer_password,
      mechanism => 'basic',
      realm     => $_st2installer_auth_basic,
      notify    => Class['nginx::service'],
      require   => Vcsrepo[$_st2installer_root],
    }
    file { $_auth_file:
      ensure  => file,
      owner   => $_nginx_daemon_user,
      group   => $_nginx_daemon_user,
      mode    => '0440',
      require => Httpauth[$_installer_username],
    }
  } else {
    $_st2installer_auth_basic = undef
    $_st2installer_auth_basic_user_file = undef
  }

  # Install updated pecan
  vcsrepo { $_st2installer_root:
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/stackstorm/st2installer',
    revision => $_st2installer_branch,
    before   => $_st2installer_before,
  }

  python::virtualenv { $_st2installer_root:
    ensure       => present,
    version      => 'system',
    systempkgs   => false,
    venv_dir     => "${_st2installer_root}/.venv",
    cwd          => $_mistral_root,
    requirements => "${_st2installer_root}/requirements.txt",
    require      => Vcsrepo[$_st2installer_root],
    before       => Service['st2installer'],
  }

  ## This creates the init script to start the
  ## st2installer service via uwsgi
  adapter::st2_uwsgi_init { 'st2installer': }

  # File permissions to allow uWSGI process to write logs
  file { $_st2installer_logfile:
    ensure  => file,
    owner   => $_nginx_daemon_user,
    group   => $_nginx_daemon_user,
    mode    => '0664',
    require => Class['::st2::profile::server'],
    before  => Service['st2installer'],
  }

  uwsgi::app { 'st2installer':
    ensure              => present,
    uid                 => $_nginx_daemon_user,
    gid                 => $_nginx_daemon_user,
    application_options => {
      'socket'       => $_st2installer_socket,
      'processes'    => 1,
      'threads'      => 10,
      'wsgi-file'    => 'app.wsgi',
      'chdir'        => '/etc/st2installer',
      'vacuum'       => true,
      'logto'        => $_st2installer_logfile,
      'virtualenv'   => "${_st2installer_root}/.venv",
      'chmod-socket' => '644',
    },
    notify           => Service['st2installer'],
  }

  nginx::resource::location { 'st2installer':
    vhost                => 'st2webui',
    ssl_only             => true,
    location             => '/setup/',
    uwsgi                => "unix://${_st2installer_socket}",
    auth_basic           => $_st2installer_auth_basic,
    auth_basic_user_file => $_st2installer_auth_basic_user_file,
    rewrite_rules        => [
      '^/setup/(.*)  /$1 break',
    ],
  }

  ### Installer needs access to a few specific files
  file { "${::settings::confdir}/hieradata/answers.yaml":
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
    before => Service['st2installer'],
  }

  ### st2installer needs access to run a few commands post-install.
  ### Installer also needs the ability to kick off a Puppet run to converge the system
  sudo::conf { "env_puppet":
    priority => '5',
    content  => 'Defaults!/usr/bin/puprun env_keep += "nocolor environment debug FACTER_installer_running"',
  }
  ### Installer also needs to try and send anonymous installation data via StackStorm
  sudo::conf { "st2-call-home":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/bin/st2 run st2.call_home",
  }
  ### Installer also needs access to reload packs into memory.
  sudo::conf { "st2ctl-reload":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/bin/st2ctl reload --register-all",
  }
  ### Installer also to be able to tell Hubot to refresh its alias list
  sudo::conf { "hubot-refresh-aliases":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/sbin/service hubot restart",
  }
  ### Installer also to be able to restart nginx
  sudo::conf { "restart-nginx":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/sbin/service nginx restart",
  }
  ### Installer also to be able to restart nginx
  sudo::conf { "delete-answer-file":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /bin/rm ${::settings::confdir}/hieradata/answers.yaml",
  }
  sudo::conf { "puppet":
    priority => '10',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/bin/puprun",
  }

  # Dependencies
  # Here lies odd dependencies that need to be put in this file. Please document them.

  ## First Run
  # Here lies a few things that need to be done only on the first run. Make sure at some point
  # that we converge all of the content on the machine. This is needed to reduce shipping size
  # of the final asset, so databases are sent un-populated.

  exec { 'register all st2 content':
    command => 'st2ctl reload --register-all',
    unless  => 'st2 action list | grep packs.install',
    path    => '/usr/bin:/usr/sbin:/bin:/sbin',
    require => Service['nginx'],
    notify  => Exec['restart st2'],
  }
  exec { 'restart st2':
    command     => 'st2ctl restart',
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    refreshonly => true,
  }

  # Reloads also need to happen anytime the hostname changes
  Host<| name == $_hostname |> {
    notify => Exec['restart st2'],
  }
}
