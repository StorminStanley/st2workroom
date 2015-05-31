class role::container_st2auth {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'auth',
  }
}
