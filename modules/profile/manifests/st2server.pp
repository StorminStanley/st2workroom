class profile::st2server {
  ### Profile Data Collection
  ### Each of these values are values that can be set via Hiera
  ### to configure this class for different environments.
  ### These values are also meant to capture data from st2installer
  ### where applicable.
  $_ssl_cert = '/etc/ssl/st2/st2.crt'
  $_ssl_key = '/etc/ssl/st2/st2.key'
  $_ssl_csr = '/etc/ssl/st2/st2.csr'
  $_ca_cert = '/etc/ssl/st2/st2_ca.crt'
  $_ca_key = '/etc/ssl/st2/st2_ca.key'
  $_user_ssl_cert = hiera('st2::ssl_public_key', undef)
  $_user_ssl_key = hiera('st2::ssl_private_key', undef)
  $_user_ca_cert = hiera('st2::ssl_ca_cert', undef)
  $_hostname = hiera('system::hostname', $::hostname)
  $_fqdn = hiera('system::fqdn', $::fqdn)
  $_host_ip = hiera('system::ipaddress', $::ipaddress)
  $_installer_workroom_mode = hiera('st2::installer_workroom_mode', '0660')
  $_st2auth_uwsgi_threads = hiera('st2::auth_uwsgi_threads', 10)
  $_st2auth_uwsgi_processes = hiera('st2::auth_uwsgi_processes', 1)
  $_st2api_threads = hiera('st2::api_uwsgi_threads', 10)
  $_st2api_processes = hiera('st2::api_uwsgi_processes', 1)
  $_st2installer_branch = hiera('st2::installer_branch', 'stable')
  $_mistral_uwsgi_threads = hiera('st2::mistral_uwsgi_threads', 25)
  $_mistral_uwsgi_processes = hiera('st2::mistral_uwsgi_processes', 1)
  $_installer_lockdown = hiera('st2::installer::lockdown', false)
  $_installer_username = hiera('st2::installer::username', 'installer')
  $_installer_password = hiera('st2::installer::password', fqdn_rand_string(32))
  $_enterprise_token = hiera('st2enterprise::token', undef)
  $_root_cli_username = 'root_cli'
  $_root_cli_password = fqdn_rand_string(32)
  $_root_cli_uid = 2000
  $_root_cli_gid = 2000

  # Syslog user differs based on distro
  $syslog_user = $::osfamily ? {
    'Debian'  => 'syslog',
    'RedHat'  => 'root'
  }

  # StackStorm Flow Setup. Only enable if there is a supplied token
  $_flow_url = $_enterprise_token ? {
    undef   => undef,
    default => '/flow',
  }

  # Need to determine the state of the Installer for purposes of User management.
  # Users and their corresponding SSH keys only need to be created during the
  # installer process. Any other management of these values may end up in
  # unnecessary overwriting of passwords/keys/etc.
  $_installer_running = $::installer_running
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
  $_offline_mode = hiera('system::offline_mode', false)

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
  $_public_api_url = "https://${_host_ip}:${_st2api_port}"
  $_public_auth_url = "https://${_host_ip}:${_st2auth_port}"
  $_mistral_url = '127.0.0.1'

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
      'Front-End-Https'             => 'on',
      'X-Content-Type-Options'      => 'nosniff',
    },
    default => {
      'Front-End-Https'           => 'on',
      'X-Content-Type-Options'    => 'nosniff',
      'Strict-Transport-Security' =>
        '"max-age=63072000; includeSubdomains; preload"',
    }
  }

  ## NGINX CORS Configuration
  ## In order to make sure all the things work with CORS, we need to provide specific custom blocks
  ## to Nginx. The options for st2api are slightly different from a generic CORS directive.
  ## To that end, each `if` logic block in nginx has been broken up into separate variables to be mix
  ## and matched using `location_raw_prepend` options on the vhost configurations
  $_allowed_headers = join([
    'x-auth-token',
    'DNT',
    'X-Mx-ReqToken',
    'Authorization',
    'X-CustomHeader',
    'Keep-Alive',
    'User-Agent',
    'X-Requested-With',
    'If-Modified-Since',
    'Cache-Control',
    'Content-Type',
  ], ",")

  $_cors_custom_options= "
    if (\$request_method = 'OPTIONS') {
			add_header 'Access-Control-Allow-Origin' '*';
      add_header 'Access-Control-Allow-Credentials' 'true';
			add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
      add_header 'Access-Control-Allow-Headers' ${_allowed_headers};
			add_header 'Access-Control-Max-Age' 1728000;
			add_header 'Content-Type' 'text/plain charset=UTF-8';
			add_header 'Content-Length' 0;

			return 204  ;
		 }"

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

  ## Note: nginx-extra contains PAM and SetHeadersMore modules
  ## Note: Service restart is setup this way to prevent puppet runs from
  ##       triggering a restart. Instead, nginx restart must be executed
  ##       manually by the user
  $_nginx_configtest = $_installer_running ? {
    undef   => undef,
    default => true,
  }

  $_nginx_package = $osfamily ? {
    'Debian'  => 'nginx-extras',
    'RedHat'  => 'nginx',
    'default' => 'nginx'
  }

  class { '::nginx':
    package_name      => "${_nginx_package}",
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
    '::profile::python',
    '::profile::rabbitmq',
    '::profile::mongodb',
  ]
  include $_st2_classes
  Class[$_st2_classes] -> Anchor['st2::pre_reqs']

  class { '::st2::profile::mistral':
    manage_postgresql => true,
    api_url           => $_mistral_url,
    api_port          => $_mistral_port,
    before            => Anchor['st2::pre_reqs'],
  }

  # Ensures Mistral is processed before Nginx
  Class['::st2::profile::mistral'] -> Class['::nginx']

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
  class { '::st2::profile::client':
    username             => $_root_cli_username,
    password             => $_root_cli_password,
    api_url              => $_api_url,
    auth_url             => $_auth_url,
    cache_token          => false,
    silence_ssl_warnings => true,
    global_env           => true,
    require              => Anchor['st2::pre_reqs'],
  }

  class { '::st2::profile::server':
    auth                   => true,
    st2api_listen_ip       => '127.0.0.1',
    manage_st2api_service  => false,
    manage_st2auth_service => false,
    manage_st2web_service  => false,
    syslog                 => true,
    before                 => Anchor['st2::pre_reqs'],
  }
  class { '::st2::auth::proxy':
    require => Class['::st2::profile::server'],
  }
  class { '::st2::profile::web':
    api_url  => "https://:${_st2api_port}",
    auth_url => "https://:${_st2auth_port}",
    flow_url => $_flow_url,
    require  => Class['::st2::profile::server'],
  }

  # Only manage the ::st2::stanley admin account
  # when the installer has either not run (managed in workroom.yaml)
  # or when the installer is or has ran (managed in answers.json)
  #
  # Answers.json is deleted by the st2installer after run to prevent
  # credential leakage. To that end, if this class still is being managed
  # and no hiera data exists, SSH keys and the admint account will be
  # overwritten with default values, and this is undesirable.
  if ! $_installer_run {
    include ::st2::stanley
  }

  include ::st2::logging::rsyslog

  # Hubot Hack
  # Because we get the environment variables via st2installer
  # and st2installer destroys the answer file as soon as it's
  # done with it. To that end, we need to do two things
  #
  # 1) Ensure that the environment file is only populated
  #    with the values we want via the installer
  # 2) Ensure that nothing is overwritten on subsequent
  #    runs of Puppet
  #
  # What this does is set the `replace` bit on the
  # Hubot environment file. This ensures that Puppet
  # DOES NOT update the contents of the file if they change
  #
  # So, we fake out the system a little bit. If the installer
  # is running, we can assume that what we have is credentials
  # if they were passed through. So, delete the empty file,
  # write the new config, and ensure it's not overwritten.
  $_hubot_env_file = "/opt/hubot/hubot/hubot.env"
  if $_installer_running {
    exec { 'remove empty hubot env settings':
      command => "rm -rf ${_hubot_env_file}",
      path    => '/usr/sbin:/usr/bin:/sbin:/bin',
    }
    Exec['remove empty hubot env settings'] -> File<| title == $_hubot_env_file |>
  }
  File<| title == $_hubot_env_file |> {
    replace => false,
  }
  ### END Hubot Hack ###

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
    install_package     => false,
    log_rotate          => 'yes',
    service_ensure      => false,
    service_enable      => false,
    install_python_dev  => false,
    install_pip         => false,
    manage_service_file => false,
  }

  python::pip { 'uwsgi':
    ensure => present,
    before => Class['::uwsgi'],
  }

  python::pip { 'gunicorn':
    ensure => present,
  }

  # ### Application Configuration
  # ### Install any and all packs defined in Hiera.
  include ::st2::packs
  include ::st2::kvs

  ## Because authentication is now being passed via Nginx, we need to make sure that
  ## the service for nginx is up and running before responding to any CLI requests
  Service['nginx'] -> Exec<| tag == 'st2::kv' |>
  Service['nginx'] -> Exec<| tag == 'st2::pack' |>

  ## SSL Certificate
  # Generate a Self-signed cert if the user does not provide cert details
  # This works by controlling the SSL Cert/Key file resources below. If
  # a user provides a key, we pass that content down through to the resource.
  # Otherwise, the cert is generated. Either way, the resources below ensure
  # proper permissioning for the webserver to read/access.
  if ! $_self_signed_cert {
    $_ssl_cert_content = $_user_ssl_cert
    $_ssl_key_content = $_user_ssl_key
    $_ca_key_content = undef
    $_ca_cert_content = $_user_ca_cert ? {
      undef   => undef,
      default => $_user_ca_cert,
    }
  } else {
    # TODO: Make this configurable with installer.
    # These map directly to the values populated in the below template

    ### This section automatically generates a self-signed CA certificate
    ### using camptocamp/openssl module.
    $_ssl_cert_content = undef
    $_ssl_key_content = undef
    $_ca_cert_content = undef
    $_ca_key_content = undef
    $_ca_expiration = '1825'
    $_ssl_expiration = '730'
    $_openssl_root = '/etc/ssl/st2'
    $_openssl_ca_config = "${_openssl_root}/ca.cnf"
    $_openssl_cert_config = "${_openssl_root}/cert.cnf"

    # Variables for OpenSSL Template
    $country = 'US'
    $state = 'California'
    $locality = 'Palo Alto'
    $organization = 'StackStorm'
    $unit = 'Information Technology'
    $commonname = $_hostname
    $email = 'support@stackstorm.com'
    $altnames = $_server_names

    file { $_openssl_ca_config:
      ensure  => file,
      owner   => $_nginx_daemon_user,
      mode    => '0444',
      content => template('profile/st2server/openssl.ca.cnf.erb'),
      notify  => Exec['remove old self-signed certs'],
      before  => Exec['create root CA'],
    }
    file { $_openssl_cert_config:
      ensure  => file,
      owner   => $_nginx_daemon_user,
      mode    => '0444',
      content => template('profile/st2server/openssl.cert.cnf.erb'),
      notify  => Exec['remove old self-signed certs'],
      before  => Exec['create root CA'],
    }

    # In the event that the configuration is refreshed, clean
    # up the old certificates to prevent cert mismatches and
    # CORS errors
    exec { 'remove old self-signed certs':
      command => "rm -rf ${_ssl_key} ${_ssl_cert} ${_ssl_csr} ${_ca_cert} ${_ca_key}",
      path    => [
        '/usr/bin',
        '/usr/sbin',
        '/bin',
        '/sbin',
      ],
      refreshonly => true,
      before      => Exec['create root CA'],
    }

    $_create_ca_command = join([
      'openssl',
      'req',
      '-new',
      '-x509',
      '-nodes',
      '-newkey',
      'rsa:2048',
      '-keyout',
      $_ca_key,
      '-out',
      $_ca_cert,
      '-config',
      $_openssl_ca_config,
      '-subj',
      "\"/C=${country}/ST=${state}/L=${locality}/O=${organization}/OU=${unit}/CN=StackStorm CA\"",
    ], ' ')

    exec { 'create root CA':
      command   => $_create_ca_command,
      creates   => $_ca_key,
      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
      logoutput => true,
      before    => Exec['create client cert req'],
    }

    $_create_client_req_command = join([
      'openssl',
      'req',
      '-new',
      '-nodes',
      '-newkey',
      'rsa:2048',
      '-keyout',
      $_ssl_key,
      '-out',
      $_ssl_csr,
      '-config',
      $_openssl_cert_config,
      '-subj',
      "\"/C=${country}/ST=${state}/L=${locality}/O=${organization}/OU=${unit}/CN=${commonname}\"",
    ], ' ')

    exec { 'create client cert req':
      command   => $_create_client_req_command,
      creates   => $_ssl_csr,
      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
      logoutput => true,
      before    => Exec['sign client cert req'],
    }

    $_timestamp = generate('/bin/date', '+%s%N')
    $_random_seed = "ssl-cert-serial-$_timestamp"
    $_sign_client_req_command = join([
      'openssl',
      'x509',
      '-req',
      '-in',
      $_ssl_csr,
      '-CA',
      $_ca_cert,
      '-CAkey',
      $_ca_key,
      '-set_serial',
      fqdn_rand(100000, $_random_seed),
      '-out',
      $_ssl_cert,
    ], ' ')

    # Tie to .rnd file is due to command needing RW permissions
    # on the file to generate state.
    exec { 'sign client cert req':
      command   => $_sign_client_req_command,
      creates   => $_ssl_cert,
      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
      logoutput => true,
      require   => File["${_openssl_root}/.rnd"],
      notify    => Service['nginx'],
    }
    ## CA Certificate END ##

    # We also must provide an endpoint for the user to go to in order
    # to download the new root CA and install it on their computer.
    # Let's setup a clean-root for this.
    #
    # Assumes the ::st2::profile::web is in play for the
    # /opt/stackstorm/static directory to exist
    #
    # Sets up an additional endpoint at $_ssl_web_location
    # attached to the installer nginx setup
    #
    # The gross hack to add this to the webui directory is special
    # thanks to nginx not being cooperative
    $_ssl_web_root     = '/opt/stackstorm/static/webui/ssl'
    $_ssl_web_location = '/ssl/'
    file { $_ssl_web_root:
      ensure  => directory,
      owner   => $_nginx_daemon_user,
      group   => $_nginx_daemon_user,
      mode    => '0755',
      require => Class['::st2::profile::web'],
    }
    file { "${_ssl_web_root}/st2_root_ca.cer":
      ensure  => file,
      owner   => $_nginx_daemon_user,
      group   => $_nginx_daemon_user,
      mode    => '0444',
      source  => $_ca_cert,
      require => File[$_ca_cert],
    }
    file { "${_ssl_web_root}/index.html":
      ensure  => file,
      owner   => $_nginx_daemon_user,
      group   => $_nginx_daemon_user,
      mode    => '0444',
      source  => 'puppet:///modules/profile/st2server/ssl_index.html',
    }
    file { "${_ssl_web_root}/StackStorm-logo.png":
      ensure  => file,
      owner   => $_nginx_daemon_user,
      group   => $_nginx_daemon_user,
      mode    => '0444',
      source  => 'puppet:///modules/profile/st2server/StackStorm-logo.png',
    }
  }

  # Ensure the SSL Certificates are owned by the proper
  # group to be readable by NGINX.
  # This relies on the NGINX daemon user belonging to the shadow
  # group, given that this is also necessary for PAM access, gives
  # a tidy way to keep permissions limited.
  file { $_openssl_root:
    ensure => directory,
    owner  => $_nginx_daemon_user,
    group  => $_nginx_daemon_user,
    mode   => '0755',
  }

  # Note: This is BAD BAD BAD
  # We use the same empty random seed file which will result in the same
  # certificate serial numbers.
  file { "${_openssl_root}/.rnd":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
  }
  file { $_ca_cert:
    ensure  => file,
    owner   => 'root',
    mode    => '0444',
    content => $_ca_cert_content,
    notify  => Class['::nginx::service'],
  }
  file { $_ca_key:
    ensure  => file,
    owner   => 'root',
    mode    => '0440',
    content => $_ca_key_content,
    notify  => Class['::nginx::service'],
  }
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

  if $_ca_cert {
    ## Add the certificate to the trusted root store to get rid
    ## of annoying issues related to self-signed or trusted
    ca_cert::ca { 'StackStorm Auto-Generated Trusted CA':
      ensure => 'trusted',
      source => "file:${_ca_cer}",
    }
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

  case $osfamily {
    'Debian': {
      file { '/etc/init/st2web.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/st2/etc/init/st2actionrunner.conf',
      }
    }
    'RedHat': {
      if $operatingsystemmajrelease == '7' {
        notify {'we need a st2web dummy systemd service': }
        #file { '/etc/systemd/system/st2web.service':
        #  ensure => file,
        #  owner  => 'root',
        #  group  => 'root',
        #  mode   => '0444',
        #}
      } elsif $operatingsystemmajrelease == '6' {
        notify {'we need a st2web dummy sysV service': }
      }
    }      
  }

  # Configure NGINX WebUI on 443
  nginx::resource::vhost { 'st2webui':
    ensure           => present,
    listen_port      => '80',
    ssl_port         => '443',
    ssl              => true,
    ssl_cert         => $_ssl_cert,
    ssl_key          => $_ssl_key,
    ssl_protocols    => $_ssl_protocols,
    ssl_ciphers      => $_cipher_list,
    rewrite_to_https => true,
    server_name      => $_server_names,
    add_header       => $_headers,
    www_root         => '/opt/stackstorm/static/webui/',
    subscribe        => File[$_ssl_cert],
  }

  # Flag set in st2ctl to prevent the SimpleHTTPServer from starting. This
  # should not be necessary with init scripts, but here just in case.
  file_line { 'st2 disable simple HTTP server':
    path => '/etc/environment',
    line => 'ST2_DISABLE_HTTPSERVER=true',
  }
  # Flag to allow st2ctl to correctly report the proper IP address.
  file_line { 'st2ctl web port':
    path => '/etc/environment',
    line => 'WEBUI_PORT=80',
  }

  adapter::st2_gunicorn_init { 'st2api':
    socket  => $_st2api_socket,
    workers => $_st2api_workers,
    threads => $_st2api_threads,
    user    => $_nginx_daemon_user,
    group   => $_nginx_daemon_user,
  }

  nginx::resource::vhost { 'st2api':
    ensure               => present,
    listen_port          => $_st2api_port,
    ssl                  => true,
    ssl_port             => $_st2api_port,
    ssl_cert             => $_ssl_cert,
    ssl_key              => $_ssl_key,
    ssl_protocols        => $_ssl_protocols,
    ssl_ciphers          => $_cipher_list,
    server_name          => $_server_names,
    proxy                => "http://unix:${_st2api_socket}",
    location_raw_prepend => [
      $_cors_custom_options,
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

  # ## Authentication
  # ### Nginx needs access to make calls to PAM, and by
  # ### extension, needs access to /etc/shadow to validate users.
  # ### Let's at least try to do this safely and consistently

  $_st2auth_custom_options = 'limit_except OPTIONS {
    auth_pam "Restricted";
    auth_pam_service_name "nginx";
    }'

  # Note: We need to return a custom 401 error since nginx pam module intercepts
  # 401 and there is no other way to do it :/
  $_st2auth_custom_401_error_handler = '
  error_page 401 =401 @401_response;

  location @401_response {
    more_set_headers "Access-Control-Allow-Origin: *";
    more_set_headers "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS";
    more_set_headers "Access-Control-Allow-Credentials: true";
    return 401 "Invalid or missing credentials";
  }'

  # Note 1: We don't need an if block since more_set_headers only sets header if
  # already set so duplicate headers are ot a problem.
  # Note 2: This module requires nginx-extras to be installed.
  # Note 3: We use MoreSetHeaders module since old version of nginx we use
  # doesn't support overriding / setting headers on non-succesful responses.
  $_st2auth_cors_custom_options = '
    more_set_headers "Access-Control-Allow-Origin: *";
    more_set_headers "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS";
    more_set_headers "Access-Control-Allow-Credentials: true";
'

  # Let's add our nginx user to the `shadow` group, but do
  # it after the package manager has installed and setup
  # the user

  group {'shadow':
    ensure => 'present'
  }

  user { $_nginx_daemon_user:
    groups  => ['shadow'],
    require => Group['shadow']
  }

  # RHEL needs shadow-utils and some perms finagling to make PAM work
  if $osfamily == 'RedHat' {
    package {'shadow-utils':
      ensure => 'present',
      require => Group['shadow'],
      before => User["$_nginx_daemon_user"]
    }

    file {'/etc/shadow':
      ensure => 'present',
      group  => 'shadow',
      require => Group['shadow'],
      before => User["$_nginx_daemon_user"]
    }
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
      'logto'        => '/var/log/st2/st2auth.uwsgi.log',
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
    raw_append => [
        $_st2auth_custom_401_error_handler,
    ],
    location_raw_append => [
      $_st2auth_cors_custom_options,
      'proxy_pass_header Authorization;',
      'uwsgi_param  REMOTE_USER        $remote_user;',
      $_st2auth_custom_options,
    ],
  }

  # Needed for uWSGI server to write to logs
  file { [
    '/var/log/st2/st2api.uwsgi.log',
    '/var/log/st2/st2auth.uwsgi.log',
  ]:
    ensure  => present,
    owner   => $_nginx_daemon_user,
    group   => $_nginx_daemon_user,
    mode    => '0664',
    require => Class['::st2::profile::server'],
    before  => [
      Adapter::St2_uwsgi_init['st2auth'],
    ],
  }

  # Ensure that the st2auth service is started up and serving before
  # attempting to download anything
  Class['::st2::profile::server'] -> Class['::nginx::service'] -> St2::Pack<||>

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
    before   => Uwsgi::App['st2installer'],
    notify   => Service['st2installer'],
  }

  python::virtualenv { $_st2installer_root:
    ensure       => present,
    version      => 'system',
    systempkgs   => false,
    venv_dir     => "${_st2installer_root}/.venv",
    cwd          => $_st2installer_root,
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
  file { "${::settings::confdir}/hieradata/answers.json":
    ensure  => file,
    replace => false,
    owner   => $_nginx_daemon_user,
    group   => $_nginx_daemon_user,
    mode    => $_installer_workroom_mode,
    content => '{}'
  }

  file { '/tmp/st2installer.log':
    ensure => file,
    owner  => $_nginx_daemon_user,
    group  => $_nginx_daemon_user,
    mode   => $_installer_workroom_mode,
    before => Service['st2installer'],
  }

  ### st2installer needs access to run a few commands post-install.
  ### Installer needs to make sure it can access the Answer file
  sudo::conf { "installer set answer file mode":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /bin/chmod",
  }
  ### Installer also needs the ability to kick off a Puppet run to converge the system
  sudo::conf { "env_puppet":
    priority => '5',
    content  => 'Defaults!/usr/bin/puprun env_keep += "NOCOLOR ENV DEBUG FACTER_installer_running"',
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
  ### Installer and clean up after itself
  sudo::conf { "delete-answer-file":
    priority => '5',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /bin/rm ${::settings::confdir}/hieradata/answers.json",
  }
  sudo::conf { "puppet":
    priority => '10',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/bin/puprun",
  }
  sudo::conf { "st2stop":
    priority => '10',
    content  => "${_nginx_daemon_user} ALL=(root) NOPASSWD: /usr/bin/st2ctl stop",
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
  }

  # Configure public url to the API endpoint.
  ini_setting { 'configure_api_public_url':
    ensure => present,
    path   => '/etc/st2/st2.conf',
    section => 'auth',
    setting => 'api_url',
    value   => $_public_api_url,
    require => Class['::st2::profile::server'],
  }

  ## Perms fix for /var/log/st2.  Needs to be added to mainline puppet module
  file { '/var/log/st2':
    ensure  => 'directory',
    mode    => '0775',
    owner   => 'root',
    group   => $syslog_user,
    recurse => true,
  }

}
