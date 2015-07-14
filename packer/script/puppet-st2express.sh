#!/usr/bin/env bash

export FACTER_role=st2express
export FACTER_datacenter=vagrant
export environment=current_working_directory

cd /opt/puppet
script/bootstrap-linux
script/puppet-apply

