#!/usr/bin/env bash

export FACTER_role=st2enterprise
export FACTER_datacenter=atlas
export environment=current_working_directory

echo "role=${FACTER_role}" > /etc/facter/facts.d/role.txt

cd /opt/puppet
script/bootstrap-linux
script/puppet-apply

echo "datacenter=vsphere" > /etc/facter/facts.d/datacenter.txt
