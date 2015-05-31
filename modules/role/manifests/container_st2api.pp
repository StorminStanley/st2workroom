class role::container_st2api {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'api',
  }
}
