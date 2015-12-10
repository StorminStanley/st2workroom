class profile::hubot{
  $_hubot_docker = hiera('hubot::docker', false)
  $_adapter_defined = hiera('hubot::adapter' undef)

  if $_hubot_docker and $_adapter_defined {
    include ::profile::hubot::docker
  } elsif not $_hubot_docker and $_adapter_defined {
    include ::profile::hubot::legacy
  } else {
    notify { 'Hubot has not been fully configured on this host yet. Please see installation instructions': }
  }
}
