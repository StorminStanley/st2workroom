#!/bin/bash

# Bail if we are not running inside VMWare.
if [[ `facter virtual` != "vmware" ]]; then
    exit 0
fi

apt-get install -y --no-install-recommends open-vm-tools open-vm-dkms
