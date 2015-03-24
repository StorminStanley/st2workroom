class profile::users {
  $users = hiera_hash('users', {})
  create_resources('users', $users)
}
