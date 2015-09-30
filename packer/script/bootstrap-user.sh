#!/usr/bin/env sh

## This script creates a bootstrap user to be used while initial machines are
## provisioning. Will be removed by first Puppet run.
USER=bootstrap

useradd --create-home $USER
echo "st@ckst0rm" | passwd "$USER" --stdin
