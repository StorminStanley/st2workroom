class role::container_st2sensorcontainer {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'sensorcontainer',
  }
}
