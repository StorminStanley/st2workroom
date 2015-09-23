#!/usr/bin/env bash

export FACTER_role=st2express
export FACTER_datacenter=us-east-1
export environment=current_working_directory

echo "datacenter=${FACTER_datacenter}" > /etc/facter/facts.d/datacenter.txt
echo "role=${FACTER_role}" > /etc/facter/facts.d/role.txt

cd /opt/puppet
script/bootstrap-os
script/puppet-apply
