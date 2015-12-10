class profile::hubot{
  $_hubot_docker = hiera('hubot::docker', false)
  $_adapter_defined = hiera('hubot::adapter', undef)

  if $_hubot_docker and $_adapter_defined {
    include ::profile::hubot::docker
  } elsif not $_hubot_docker and $_adapter_defined {
    include ::profile::hubot::legacy
  } else {
    notify { 'ST2 Hubot is not configured for this host. Please see installation instructions if this is in error': }
  }
}
