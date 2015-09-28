#!/bin/bash

PROJECT_ROOT=/opt/puppet
export PATH=${PROJECT_ROOT}/bin:/usr/local/bin:$PATH
cd $PROJECT_ROOT

apt-get -y install open-vm-tools open-vm-tools-dkms
