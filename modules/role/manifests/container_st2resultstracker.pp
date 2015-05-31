class role::container_st2resultstracker {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'resultstracker',
  }
}
