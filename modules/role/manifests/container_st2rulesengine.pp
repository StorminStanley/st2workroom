class role::container_st2rulesengine {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'rulesengine',
  }
}
