#!/usr/bin/env sh

## This script creates a bootstrap user to be used while initial machines are
## provisioning. Will be removed by first Puppet run.
## See Class['::profile::infrastructure']

# See LastPass for bootstrap password
USER="bootstrap"
PASSWORD_HASH='$6$fyfRT6IWkc7IYC8$JSpW3AQuM6XFtfy5lFTRoThVBSYgZiZWJvU0.5D0WpqSsyML/U3dBbX9XB1doKh1tA/73j77Ghs0jNF9adwh7.'

useradd --create-home $USER
usermod -p $PASSWORD_HASH $USER
