class profile::python {
  include ::st2::profile::python
  package { 'pip':
    ensure   => 'latest',
    provider => 'pip',
  }
}
