#!/usr/bin/env bash

export FACTER_role=st2express
export FACTER_datacenter=atlas
export environment=current_working_directory

echo "role=${FACTER_role}" > /etc/facter/facts.d/role.txt

cd /opt/puppet
script/bootstrap-linux
script/puppet-apply

# This sets the future datacenter to run in the context of Vagrant
# Atlas datacenter has a slightly different profile to allow
# a build.
echo "datacenter=vagrant" > /etc/facter/facts.d/datacenter.txt
