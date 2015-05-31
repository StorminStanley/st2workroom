class role::container_st2notifier {
  include role::container_st2base

  class { '::st2::container':
    subsystem => 'notifier',
  }
}
