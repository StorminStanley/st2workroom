# Class: puppet
#
# This module manages git servers and clients
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class puppet(
  $version = '1.2.0',
) {
  require puppet::deps

}
