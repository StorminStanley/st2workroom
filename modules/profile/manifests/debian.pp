class profile::debian {
  $_http_proxy = hiera('system::http_proxy', undef)

  $_is_https = $_http_proxy ? {
    /^https/ => true,
    default  => false,
  }

  ## This section parses the proxy and prepares it for usage in
  ## the puppetlabs/puppetlabs-apt module.
  if $_http_proxy {
    $_parser = @("EOF"/)
    require 'uri'
    uri = URI.parse(@_http_proxy)
    [uri.host, uri.port]
    | EOF

    $_parse_url = inline_template('<%= @_parser %>')

    $_proxy = {
      ensure => file,
      host   => $_parse_url[0],
      port   => $_parse_url[1],
      https  => $_is_https,
    }
  } else {
    $_proxy = undef
  }

  class { '::apt':
    proxy => $_proxy,
  }
}
