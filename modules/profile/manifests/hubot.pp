class profile::hubot{
  $_hubot_docker = hiera('hubot::docker', false)

  if $_hubot_docker {
    include ::profile::hubot::docker
  } else {
    include ::profile::hubot::legacy
  }
}
