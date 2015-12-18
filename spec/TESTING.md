# Testing

Testing for this repository happens in two ways:

1) Ensuring that Puppet Logic is valid with `rspec-puppet`
2) Ensuring that post-configuration, system is up and running with `bats`

## Test Directory Structure

* spec
  - bats
  - classes
  - defines
  - functions
  - hosts

## `bats`

Read up at https://github.com/sstephenson/bats

* Add test helpers to `spec/bats/test-helpers.bash`

## `rspec-puppet`

Read up at http://rspec-puppet.com

* Add puppet classes to the `spec/classes` directory
* Add puppet defined types to the `spec/defines` directory
