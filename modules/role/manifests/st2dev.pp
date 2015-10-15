class role::st2dev {
  include ::profile::infrastructure
  include ::profile::st2_dependencies
  include ::profile::hubot
  include ::profile::users
  include ::profile::auth_backend_pam
}
