class profile::bootstrap {
  # Removes the bootstrap user if exists
  user { 'bootstrap':
    ensure => absent,
  }
}
