#!/usr/bin/env bash

export FACTER_role=st2express
export FACTER_datacenter=us-east-1
export environment=current_working_directory

cd /opt/puppet
script/bootstrap-linux
script/puppet-apply
