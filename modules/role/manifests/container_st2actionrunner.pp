class role::container_st2actionrunner {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'actionrunner',
  }
}
